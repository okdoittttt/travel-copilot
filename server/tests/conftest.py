import asyncio
import os
import time
import uuid
from collections.abc import AsyncIterator, Iterator
from contextlib import asynccontextmanager
from dataclasses import dataclass
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

from travel_copilot.auth.access_token import create_access_token
from travel_copilot.auth.google import GOOGLE_JWKS_URL
from travel_copilot.core.config import Settings
from travel_copilot.directions.client import COMPUTE_ROUTES_URL
from travel_copilot.main import create_app
from travel_copilot.places.client import AUTOCOMPLETE_URL, PLACES_BASE_URL
from travel_copilot.trips.models import TripMember, TripRole
from travel_copilot.users.models import User

SERVER_DIR = Path(__file__).resolve().parent.parent

# 연결되지 않는 주소. DB 장애 상황을 흉내 낼 때 쓴다.
UNREACHABLE_DATABASE_URL = "postgresql+asyncpg://nobody:nopass@127.0.0.1:1/none"

TEST_JWT_SECRET = "test-only-jwt-secret-0123456789abcdef"
WEB_CLIENT_ID = "test-web.apps.googleusercontent.com"
IOS_CLIENT_ID = "test-ios.apps.googleusercontent.com"
ANDROID_CLIENT_ID = "test-android.apps.googleusercontent.com"
GOOGLE_KID = "test-kid-1"
# 가짜 Places 키. 비밀값 검사에 걸리지 않게 반복 문자열로 만든다
PLACES_KEY = "places" * 6


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
        "google_places_api_key": PLACES_KEY,
        "location_cleanup_interval_seconds": 0,
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
        await conn.execute(text("TRUNCATE users, auth_nonces, trips RESTART IDENTITY CASCADE"))
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


# --- 사용자·여행 도우미 ------------------------------------------------------


@dataclass(frozen=True)
class SeededUser:
    id: uuid.UUID
    display_name: str
    headers: dict[str, str]


async def create_user(db: AsyncSession, display_name: str = "여행자") -> SeededUser:
    """Google 로그인을 거치지 않고 사용자와 액세스 토큰을 만든다.

    로그인 API는 IP 기준 요청 횟수 제한이 있어, 여러 사용자가 필요한 테스트는 이 도우미를 쓴다.
    """
    user = User(display_name=display_name, email=f"{uuid.uuid4().hex}@example.com")
    db.add(user)
    await db.commit()
    token = create_access_token(user.id, TEST_JWT_SECRET, ttl_seconds=900)
    return SeededUser(id=user.id, display_name=display_name, headers=bearer(token))


async def add_member(db: AsyncSession, trip_id: str, user: SeededUser, role: TripRole) -> None:
    """여행에 멤버를 바로 넣는다 (초대 기능은 F5)."""
    db.add(TripMember(trip_id=uuid.UUID(trip_id), user_id=user.id, role=role))
    await db.commit()


TRIP_BODY: dict[str, Any] = {
    "title": "파리 가족여행",
    "destination": "프랑스 파리",
    "start_date": "2026-12-20",
    "end_date": "2026-12-27",
    "timezone": "Europe/Paris",
}


async def create_trip(client: AsyncClient, owner: SeededUser, **overrides: Any) -> dict[str, Any]:
    """API로 여행을 만들고 응답 본문을 돌려준다."""
    response = await client.post(
        "/api/v1/trips", json={**TRIP_BODY, **overrides}, headers=owner.headers
    )
    assert response.status_code == 201, response.text
    trip: dict[str, Any] = response.json()
    return trip


# --- 가짜 Google Places (실제 Google을 호출하지 않는다) ----------------------

ORSAY_ID = "ChIJG5Y_dinR5kcRWgfbpjyYXmU"
ORSAY_LOCATION = {"latitude": 48.86, "longitude": 2.3266}


def place_details_body(place_id: str = ORSAY_ID, **overrides: Any) -> dict[str, Any]:
    body: dict[str, Any] = {
        "id": place_id,
        "formattedAddress": "1 Rue de la Légion d'Honneur, 75007 Paris, 프랑스",
        "location": ORSAY_LOCATION,
    }
    body.update(overrides)
    return body


@pytest.fixture
def google_places() -> Iterator[respx.MockRouter]:
    """Places 자동완성·장소 상세를 가짜 응답으로 바꾼다. 경로 이름: autocomplete, details."""
    with respx.mock(assert_all_called=False) as mock:
        mock.post(AUTOCOMPLETE_URL, name="autocomplete").respond(
            json={
                "suggestions": [
                    {
                        "placePrediction": {
                            "placeId": ORSAY_ID,
                            "structuredFormat": {
                                "mainText": {"text": "오르세 미술관"},
                                "secondaryText": {"text": "프랑스 파리"},
                            },
                        }
                    }
                ]
            }
        )
        mock.get(url__startswith=f"{PLACES_BASE_URL}/places/", name="details").respond(
            json=place_details_body()
        )
        yield mock


async def add_item(
    client: AsyncClient, user: SeededUser, trip_id: str, **fields: Any
) -> dict[str, Any]:
    """API로 일정 항목을 추가하고 응답 본문을 돌려준다. 기본 날짜는 여행 둘째 날."""
    body = {"day": "2026-12-21", "title": "일정", **fields}
    response = await client.post(f"/api/v1/trips/{trip_id}/items", json=body, headers=user.headers)
    assert response.status_code == 201, response.text
    item: dict[str, Any] = response.json()
    return item


# --- 가짜 Google Routes -------------------------------------------------------

LOUVRE_ID = "ChIJD3uTd9hx5kcR1IQvGfr8dbk"
EIFFEL_ID = "ChIJLU7jZClu5kcR4PcOOO6p3I0"


@pytest.fixture
def google_routes(google_places: respx.MockRouter) -> respx.MockRouter:
    """Routes computeRoutes를 가짜 응답으로 바꾼다 (Places 가짜와 같은 mock). 경로 이름: routes."""
    google_places.post(COMPUTE_ROUTES_URL, name="routes").respond(
        json={"routes": [{"duration": "1260s", "distanceMeters": 3900}]}
    )
    return google_places


# --- 초대 도우미 --------------------------------------------------------------


async def create_invite(
    client: AsyncClient, owner: SeededUser, trip_id: str, **body: Any
) -> dict[str, Any]:
    """API로 초대 링크를 만들고 응답 본문을 돌려준다. 토큰은 `token` 키로 같이 넣어 준다."""
    response = await client.post(
        f"/api/v1/trips/{trip_id}/invites", json=body, headers=owner.headers
    )
    assert response.status_code == 201, response.text
    invite: dict[str, Any] = response.json()
    invite["token"] = invite["url"].split("#", 1)[1]
    return invite
