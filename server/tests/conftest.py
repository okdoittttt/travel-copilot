import asyncio
import os
import time
from collections.abc import AsyncIterator, Iterator
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

import jwt
import pytest
import respx
from alembic import command
from alembic.config import Config
from asgi_lifespan import LifespanManager
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from travel_copilot.auth.google import GOOGLE_JWKS_URL
from travel_copilot.core.config import Settings
from travel_copilot.main import create_app

SERVER_DIR = Path(__file__).resolve().parent.parent

# 연결되지 않는 주소. DB 장애 상황을 흉내 낼 때 쓴다.
UNREACHABLE_DATABASE_URL = "postgresql+asyncpg://nobody:nopass@127.0.0.1:1/none"

TEST_JWT_SECRET = "test-only-jwt-secret-0123456789abcdef"
WEB_CLIENT_ID = "test-web.apps.googleusercontent.com"
IOS_CLIENT_ID = "test-ios.apps.googleusercontent.com"
ANDROID_CLIENT_ID = "test-android.apps.googleusercontent.com"
GOOGLE_KID = "test-kid-1"


def get_test_database_url() -> str:
    url = os.environ.get("TEST_DATABASE_URL")
    if not url:
        pytest.fail("TEST_DATABASE_URL 환경변수가 필요합니다 (docs/00-getting-started.md 4.1절).")
    return url


def make_settings(**overrides: Any) -> Settings:
    values: dict[str, Any] = {
        "env": "local",
        "database_url": UNREACHABLE_DATABASE_URL,
        "jwt_secret": TEST_JWT_SECRET,
        "google_web_client_id": WEB_CLIENT_ID,
        "google_allowed_azp": f"{IOS_CLIENT_ID},{ANDROID_CLIENT_ID}",
    }
    values.update(overrides)
    return Settings(**values)


@asynccontextmanager
async def client_for(app: FastAPI) -> AsyncIterator[AsyncClient]:
    async with LifespanManager(app) as manager:
        # 처리되지 않은 예외도 실제 서버처럼 500 응답으로 받기 위해 raise_app_exceptions=False
        transport = ASGITransport(app=manager.app, raise_app_exceptions=False)
        async with AsyncClient(transport=transport, base_url="https://testserver") as client:
            yield client


# --- 테스트 DB ---------------------------------------------------------------


async def _reset_schema(url: str) -> None:
    engine = create_async_engine(url)
    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
    await engine.dispose()


@pytest.fixture(scope="session")
def migrated_database_url() -> str:
    """테스트 DB를 비우고 마이그레이션을 끝까지 적용한다 (테스트 실행마다 한 번)."""
    url = get_test_database_url()
    asyncio.run(_reset_schema(url))
    previous = os.environ.get("DATABASE_URL")
    os.environ["DATABASE_URL"] = url
    try:
        command.upgrade(Config(str(SERVER_DIR / "alembic.ini")), "head")
    finally:
        if previous is None:
            os.environ.pop("DATABASE_URL", None)
        else:
            os.environ["DATABASE_URL"] = previous
    return url


@pytest.fixture
async def db(migrated_database_url: str) -> AsyncIterator[AsyncSession]:
    """테스트가 DB를 직접 확인할 때 쓰는 세션. 테스트 시작 전에 모든 데이터를 지운다."""
    engine = create_async_engine(migrated_database_url)
    async with engine.begin() as conn:
        await conn.execute(text("TRUNCATE users, auth_nonces RESTART IDENTITY CASCADE"))
    async with async_sessionmaker(engine, expire_on_commit=False)() as session:
        yield session
    await engine.dispose()


@pytest.fixture
async def client(db: AsyncSession, migrated_database_url: str) -> AsyncIterator[AsyncClient]:
    """실제 테스트 DB에 연결된 앱의 클라이언트."""
    app = create_app(make_settings(database_url=migrated_database_url))
    async with client_for(app) as c:
        yield c


@pytest.fixture
async def client_without_db() -> AsyncIterator[AsyncClient]:
    """DB 없이 동작하는 경로를 확인할 때 쓰는 클라이언트."""
    app = create_app(make_settings())
    async with client_for(app) as c:
        yield c


# --- 가짜 Google (실제 Google을 호출하지 않는다) -----------------------------


@pytest.fixture(scope="session")
def google_private_key() -> rsa.RSAPrivateKey:
    return rsa.generate_private_key(public_exponent=65537, key_size=2048)


@pytest.fixture
def google_jwks(google_private_key: rsa.RSAPrivateKey) -> Iterator[respx.MockRouter]:
    """Google 공개키(JWKS) 주소를 가짜 응답으로 바꾼다."""
    jwk: dict[str, Any] = jwt.algorithms.RSAAlgorithm.to_jwk(
        google_private_key.public_key(), as_dict=True
    )
    jwk.update({"kid": GOOGLE_KID, "alg": "RS256", "use": "sig"})
    with respx.mock(assert_all_called=False) as mock:
        mock.get(GOOGLE_JWKS_URL).respond(
            json={"keys": [jwk]}, headers={"Cache-Control": "public, max-age=3600"}
        )
        yield mock


def google_claims(nonce: str, **overrides: Any) -> dict[str, Any]:
    now = int(time.time())
    claims: dict[str, Any] = {
        "iss": "https://accounts.google.com",
        "aud": WEB_CLIENT_ID,
        "azp": IOS_CLIENT_ID,
        "sub": "google-sub-1",
        "email": "traveler@example.com",
        "email_verified": True,
        "name": "Google 이름",
        "iat": now,
        "exp": now + 3600,
        "nonce": nonce,
    }
    claims.update(overrides)
    return {key: value for key, value in claims.items() if value is not None}


def sign_google_token(claims: dict[str, Any], key: rsa.RSAPrivateKey, kid: str = GOOGLE_KID) -> str:
    return jwt.encode(claims, key, algorithm="RS256", headers={"kid": kid})


async def issue_nonce(client: AsyncClient) -> str:
    response = await client.post("/api/v1/auth/nonce")
    assert response.status_code == 200
    nonce: str = response.json()["nonce"]
    return nonce


async def google_login(
    client: AsyncClient, key: rsa.RSAPrivateKey, display_name: str | None = None, **claims: Any
) -> dict[str, Any]:
    """nonce 발급부터 로그인까지 한 번에 하고 응답 본문을 돌려준다."""
    nonce = await issue_nonce(client)
    body: dict[str, Any] = {"id_token": sign_google_token(google_claims(nonce, **claims), key)}
    if display_name is not None:
        body["display_name"] = display_name
    response = await client.post("/api/v1/auth/google/login", json=body)
    assert response.status_code == 200, response.text
    result: dict[str, Any] = response.json()
    return result


def bearer(access_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {access_token}"}
