"""T01·T02: Google ID 토큰 검증과 사용자 식별."""

import base64
import hashlib
import hmac
import json
from typing import Any

import respx
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from httpx import AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import (
    GOOGLE_KID,
    google_claims,
    google_login,
    issue_nonce,
    sign_google_token,
)
from travel_copilot.users.models import User

LOGIN = "/api/v1/auth/google/login"


async def _login_status(client: AsyncClient, id_token: str) -> tuple[int, dict[str, Any]]:
    response = await client.post(LOGIN, json={"id_token": id_token})
    return response.status_code, response.json()


def _b64(data: dict[str, Any]) -> str:
    raw = json.dumps(data, separators=(",", ":")).encode()
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


async def test_google_login_with_valid_token_succeeds(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    body = await google_login(client, google_private_key)

    assert body["is_new_user"] is True
    assert body["token_type"] == "Bearer"


async def test_google_login_with_forged_signature_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter
) -> None:
    attacker_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    nonce = await issue_nonce(client)

    status, body = await _login_status(
        client, sign_google_token(google_claims(nonce), attacker_key)
    )

    assert status == 401
    assert body["code"] == "id_token_invalid"


async def test_google_login_with_other_audience_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    nonce = await issue_nonce(client)
    token = sign_google_token(
        google_claims(nonce, aud="other-app.apps.googleusercontent.com"), google_private_key
    )

    status, body = await _login_status(client, token)

    assert status == 401
    assert body["code"] == "id_token_invalid"


async def test_google_login_with_wrong_issuer_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    nonce = await issue_nonce(client)
    token = sign_google_token(
        google_claims(nonce, iss="https://evil.example.com"), google_private_key
    )

    status, _ = await _login_status(client, token)

    assert status == 401


async def test_google_login_with_expired_token_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    nonce = await issue_nonce(client)
    claims = google_claims(nonce)
    claims["iat"] -= 7200
    claims["exp"] = claims["iat"] + 3600  # 1시간 전에 만료 (허용 오차 60초 밖)

    status, _ = await _login_status(client, sign_google_token(claims, google_private_key))

    assert status == 401


async def test_google_login_with_alg_none_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter
) -> None:
    nonce = await issue_nonce(client)
    unsigned = f"{_b64({'alg': 'none', 'kid': GOOGLE_KID})}.{_b64(google_claims(nonce))}."

    status, _ = await _login_status(client, unsigned)

    assert status == 401


async def test_google_login_with_alg_confusion_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    # 공개키(누구나 아는 값)를 HS256 비밀키로 써서 만든 위조 토큰
    public_pem = google_private_key.public_key().public_bytes(
        serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo
    )
    nonce = await issue_nonce(client)
    # 라이브러리는 이런 토큰을 만들어주지 않으므로 공격자처럼 직접 HMAC 서명한다
    signing_input = f"{_b64({'alg': 'HS256', 'kid': GOOGLE_KID})}.{_b64(google_claims(nonce))}"
    signature = hmac.new(public_pem, signing_input.encode(), hashlib.sha256).digest()
    forged = f"{signing_input}.{base64.urlsafe_b64encode(signature).rstrip(b'=').decode()}"

    status, _ = await _login_status(client, forged)

    assert status == 401


async def test_google_login_with_unknown_azp_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    nonce = await issue_nonce(client)
    token = sign_google_token(
        google_claims(nonce, azp="someone-else.apps.googleusercontent.com"), google_private_key
    )

    status, _ = await _login_status(client, token)

    assert status == 401


async def test_google_login_nonce_missing_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    claims = google_claims("unused")
    del claims["nonce"]

    status, body = await _login_status(client, sign_google_token(claims, google_private_key))

    assert status == 401
    assert body["code"] == "id_token_invalid"


async def test_google_login_nonce_unknown_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    token = sign_google_token(google_claims("never-issued-nonce"), google_private_key)

    status, body = await _login_status(client, token)

    assert status == 401
    assert body["code"] == "nonce_invalid"


async def test_google_login_nonce_expired_returns_401(
    client: AsyncClient,
    db: AsyncSession,
    google_jwks: respx.MockRouter,
    google_private_key: rsa.RSAPrivateKey,
) -> None:
    from sqlalchemy import text

    nonce = await issue_nonce(client)
    await db.execute(text("UPDATE auth_nonces SET expires_at = now() - interval '1 second'"))
    await db.commit()

    status, body = await _login_status(
        client, sign_google_token(google_claims(nonce), google_private_key)
    )

    assert status == 401
    assert body["code"] == "nonce_invalid"


async def test_google_login_nonce_reuse_returns_401(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    nonce = await issue_nonce(client)
    token = sign_google_token(google_claims(nonce), google_private_key)

    first, _ = await _login_status(client, token)
    second, body = await _login_status(client, token)  # 가로챈 토큰 재전송

    assert first == 200
    assert second == 401
    assert body["code"] == "nonce_invalid"


async def test_same_email_different_sub_creates_separate_users(
    client: AsyncClient,
    db: AsyncSession,
    google_jwks: respx.MockRouter,
    google_private_key: rsa.RSAPrivateKey,
) -> None:
    victim = await google_login(
        client, google_private_key, sub="victim-sub", email="shared@example.com"
    )
    attacker = await google_login(
        client, google_private_key, sub="attacker-sub", email="shared@example.com"
    )

    assert attacker["is_new_user"] is True
    assert attacker["user"]["id"] != victim["user"]["id"]
    assert await db.scalar(select(func.count()).select_from(User)) == 2


async def test_id_token_failure_reason_not_in_response(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    nonce = await issue_nonce(client)
    token = sign_google_token(google_claims(nonce, aud="other"), google_private_key)

    response = await client.post(LOGIN, json={"id_token": token})

    assert "aud" not in response.text.lower()
    assert "audience" not in response.text.lower()
