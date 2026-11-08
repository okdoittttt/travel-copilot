import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

import pytest
from asgi_lifespan import LifespanManager
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

from travel_copilot.core.config import Settings
from travel_copilot.main import create_app

# 연결되지 않는 주소. DB 장애 상황을 흉내 낼 때 쓴다.
UNREACHABLE_DATABASE_URL = "postgresql+asyncpg://nobody:nopass@127.0.0.1:1/none"


def get_test_database_url() -> str:
    url = os.environ.get("TEST_DATABASE_URL")
    if not url:
        pytest.fail(
            "TEST_DATABASE_URL 환경변수가 필요합니다. README의 '서버 테스트' 항목을 참고하세요."
        )
    return url


def make_settings(**overrides: Any) -> Settings:
    values: dict[str, Any] = {"env": "local", "database_url": UNREACHABLE_DATABASE_URL}
    values.update(overrides)
    return Settings(**values)


@asynccontextmanager
async def client_for(app: FastAPI) -> AsyncIterator[AsyncClient]:
    async with LifespanManager(app) as manager:
        # 처리되지 않은 예외도 실제 서버처럼 500 응답으로 받기 위해 raise_app_exceptions=False
        transport = ASGITransport(app=manager.app, raise_app_exceptions=False)
        async with AsyncClient(transport=transport, base_url="https://testserver") as client:
            yield client


@pytest.fixture
async def client() -> AsyncIterator[AsyncClient]:
    """실제 테스트 DB에 연결된 앱의 클라이언트."""
    app = create_app(make_settings(database_url=get_test_database_url()))
    async with client_for(app) as c:
        yield c


@pytest.fixture
async def client_without_db() -> AsyncIterator[AsyncClient]:
    """DB 없이 동작하는 경로를 확인할 때 쓰는 클라이언트."""
    app = create_app(make_settings())
    async with client_for(app) as c:
        yield c
