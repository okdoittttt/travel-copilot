"""T03·T04·T05·T25: 자체 토큰 교체·폐기, 요청 횟수 제한, 로그."""

import base64
import json
import logging
import time
import uuid
from collections.abc import Iterator

import jwt
import pytest
import respx
from cryptography.hazmat.primitives.asymmetric import rsa
from httpx import AsyncClient
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import (
    TEST_JWT_SECRET,
    bearer,
    client_for,
    google_claims,
    google_login,
    issue_nonce,
    make_settings,
    sign_google_token,
)
from travel_copilot.auth.access_token import AUDIENCE, ISSUER
from travel_copilot.auth.models import RefreshToken
from travel_copilot.core.logging import JsonFormatter
from travel_copilot.core.tokens import hash_token
from travel_copilot.main import create_app

# 서버 키와 다른 서명 키 (위조 토큰용). 비밀값 검사에 걸리지 않게 반복 문자열로 만든다
ATTACKER_KEY = "attacker" * 5
REFRESH = "/api/v1/auth/refresh"
ME = "/api/v1/me"


def _access_token(**overrides: object) -> str:
    now = int(time.time())
    claims: dict[str, object] = {
        "sub": str(uuid.uuid4()),
        "iss": ISSUER,
        "aud": AUDIENCE,
        "iat": now,
        "exp": now + 900,
    }
    claims.update(overrides)
    secret = str(claims.pop("_secret", TEST_JWT_SECRET))
    return jwt.encode(claims, secret, algorithm="HS256")


# --- 리프레시 토큰 ------------------------------------------------------------


async def test_refresh_rotates_token(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    login = await google_login(client, google_private_key)

    response = await client.post(REFRESH, json={"refresh_token": login["refresh_token"]})

    assert response.status_code == 200
    assert response.json()["refresh_token"] != login["refresh_token"]


async def test_refresh_token_reuse_revokes_family(
    client: AsyncClient,
    db: AsyncSession,
    google_jwks: respx.MockRouter,
    google_private_key: rsa.RSAPrivateKey,
) -> None:
    login = await google_login(client, google_private_key)
    stolen = login["refresh_token"]
    rotated = (await client.post(REFRESH, json={"refresh_token": stolen})).json()["refresh_token"]

    reuse = await client.post(REFRESH, json={"refresh_token": stolen})  # 탈취된 옛 토큰 사용
    after = await client.post(REFRESH, json={"refresh_token": rotated})  # 정상 사용자의 새 토큰

    assert reuse.status_code == 401
    assert after.status_code == 401, "재사용이 감지되면 같은 묶음의 최신 토큰도 폐기돼야 한다"
    revoked = await db.scalars(select(RefreshToken.revoked_at))
    assert all(value is not None for value in revoked)


async def test_refresh_token_stored_as_hash(
    client: AsyncClient,
    db: AsyncSession,
    google_jwks: respx.MockRouter,
    google_private_key: rsa.RSAPrivateKey,
) -> None:
    login = await google_login(client, google_private_key)

    stored = list(await db.scalars(select(RefreshToken.token_hash)))

    assert stored == [hash_token(login["refresh_token"])]
    assert login["refresh_token"] not in stored


async def test_refresh_with_unknown_token_returns_401(client: AsyncClient) -> None:
    response = await client.post(REFRESH, json={"refresh_token": "not-a-real-token"})

    assert response.status_code == 401
    assert response.json()["code"] == "token_invalid"


async def test_refresh_after_logout_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    login = await google_login(client, google_private_key)

    logout = await client.post(
        "/api/v1/auth/logout",
        json={"refresh_token": login["refresh_token"]},
        headers=bearer(login["access_token"]),
    )
    response = await client.post(REFRESH, json={"refresh_token": login["refresh_token"]})

    assert logout.status_code == 204
    assert response.status_code == 401


async def test_logout_cannot_revoke_other_users_token(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    victim = await google_login(client, google_private_key, sub="victim")
    attacker = await google_login(client, google_private_key, sub="attacker")

    await client.post(
        "/api/v1/auth/logout",
        json={"refresh_token": victim["refresh_token"]},
        headers=bearer(attacker["access_token"]),
    )
    response = await client.post(REFRESH, json={"refresh_token": victim["refresh_token"]})

    assert response.status_code == 200


async def test_expired_refresh_token_returns_401(
    client: AsyncClient,
    db: AsyncSession,
    google_jwks: respx.MockRouter,
    google_private_key: rsa.RSAPrivateKey,
) -> None:
    login = await google_login(client, google_private_key)
    await db.execute(text("UPDATE refresh_tokens SET expires_at = now() - interval '1 second'"))
    await db.commit()

    response = await client.post(REFRESH, json={"refresh_token": login["refresh_token"]})

    assert response.status_code == 401


# --- 액세스 토큰 --------------------------------------------------------------


async def test_access_token_of_deleted_user_returns_401(
    client: AsyncClient,
    db: AsyncSession,
    google_jwks: respx.MockRouter,
    google_private_key: rsa.RSAPrivateKey,
) -> None:
    login = await google_login(client, google_private_key)
    await db.execute(text("DELETE FROM users"))
    await db.commit()

    response = await client.get(ME, headers=bearer(login["access_token"]))

    assert response.status_code == 401
    assert response.json()["code"] == "token_invalid"


@pytest.mark.parametrize(
    ("token_overrides", "expected_code"),
    [
        ({"_secret": ATTACKER_KEY}, "token_invalid"),
        ({"exp": int(time.time()) - 10}, "token_expired"),
        ({"aud": "someone-else"}, "token_invalid"),
        ({"iss": "someone-else"}, "token_invalid"),
        ({"sub": "not-a-uuid"}, "token_invalid"),
    ],
    ids=["forged", "expired", "wrong_aud", "wrong_iss", "bad_sub"],
)
async def test_access_token_rejected(
    client: AsyncClient, token_overrides: dict[str, object], expected_code: str
) -> None:
    response = await client.get(ME, headers=bearer(_access_token(**token_overrides)))

    assert response.status_code == 401
    assert response.json()["code"] == expected_code
    assert response.headers["www-authenticate"] == "Bearer"


async def test_access_token_alg_none_rejected(client: AsyncClient) -> None:
    def b64(data: dict[str, object]) -> str:
        raw = json.dumps(data, separators=(",", ":")).encode()
        return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()

    claims = {"sub": str(uuid.uuid4()), "iss": ISSUER, "aud": AUDIENCE, "exp": time.time() + 900}
    unsigned = f"{b64({'alg': 'none', 'typ': 'JWT'})}.{b64(claims)}."

    response = await client.get(ME, headers=bearer(unsigned))

    assert response.status_code == 401


async def test_missing_authorization_returns_401(client: AsyncClient) -> None:
    response = await client.get(ME)

    assert response.status_code == 401
    assert response.json()["code"] == "token_missing"


# --- 요청 횟수 제한 -----------------------------------------------------------


async def test_auth_rate_limit_returns_429(migrated_database_url: str, db: AsyncSession) -> None:
    app = create_app(
        make_settings(database_url=migrated_database_url, auth_rate_limit_per_minute=3)
    )
    async with client_for(app) as client:
        statuses = [(await client.post("/api/v1/auth/nonce")).status_code for _ in range(4)]
        last = await client.post("/api/v1/auth/nonce")

    assert statuses == [200, 200, 200, 429]
    assert last.json()["code"] == "rate_limited"
    assert int(last.headers["retry-after"]) >= 1


# --- 로그 ---------------------------------------------------------------------


class _ListHandler(logging.Handler):
    def __init__(self) -> None:
        super().__init__()
        self.lines: list[str] = []

    def emit(self, record: logging.LogRecord) -> None:
        self.lines.append(JsonFormatter().format(record))


@pytest.fixture
def all_logs() -> Iterator[_ListHandler]:
    handler = _ListHandler()
    root = logging.getLogger()
    root.addHandler(handler)
    yield handler
    root.removeHandler(handler)


async def test_auth_logs_exclude_tokens(
    client: AsyncClient,
    google_jwks: respx.MockRouter,
    google_private_key: rsa.RSAPrivateKey,
    all_logs: _ListHandler,
) -> None:
    nonce = await issue_nonce(client)
    id_token = sign_google_token(google_claims(nonce), google_private_key)
    login = (await client.post("/api/v1/auth/google/login", json={"id_token": id_token})).json()
    await client.post(REFRESH, json={"refresh_token": login["refresh_token"]})
    await client.post(REFRESH, json={"refresh_token": login["refresh_token"]})  # 재사용 경고 로그

    joined = "\n".join(all_logs.lines)
    assert "리프레시 토큰 재사용 감지" in joined
    for secret in (nonce, id_token, login["access_token"], login["refresh_token"]):
        assert secret not in joined
