"""FastAPI 앱 생성."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI

from travel_copilot.auth.google import GoogleIdTokenVerifier, GoogleJwksCache
from travel_copilot.auth.router import router as auth_router
from travel_copilot.core.config import Settings, get_settings
from travel_copilot.core.db import create_engine, create_sessionmaker
from travel_copilot.core.errors import register_error_handlers
from travel_copilot.core.logging import configure_logging
from travel_copilot.core.middleware import RequestContextMiddleware
from travel_copilot.core.rate_limit import SlidingWindowRateLimiter
from travel_copilot.health.router import router as health_router
from travel_copilot.users.router import router as users_router

API_PREFIX = "/api/v1"

# 외부 HTTP 호출 타임아웃 (08-conventions S5)
HTTP_TIMEOUT = httpx.Timeout(10.0, connect=3.0)


def create_app(settings: Settings | None = None) -> FastAPI:
    """설정에 맞춰 FastAPI 앱을 만든다.

    uvicorn에서는 `--factory` 옵션으로 이 함수를 호출한다. 모듈을 import하는
    것만으로 환경변수를 읽지 않게 해서, 테스트가 설정을 직접 넣을 수 있게 한다.

    Args:
        settings: 사용할 설정. 없으면 환경변수에서 읽는다.

    Returns:
        라우터, 미들웨어, 에러 핸들러가 등록된 앱.
    """
    settings = settings or get_settings()
    configure_logging(settings.log_level)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        engine = create_engine(settings)
        app.state.sessionmaker = create_sessionmaker(engine)
        async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as http:
            app.state.google_verifier = GoogleIdTokenVerifier(
                GoogleJwksCache(http),
                web_client_id=settings.google_web_client_id,
                allowed_azp=settings.google_allowed_azp_set,
            )
            try:
                yield
            finally:
                await engine.dispose()

    app = FastAPI(
        title="Travel Copilot API",
        lifespan=lifespan,
        # API 지도를 외부에 주지 않도록 로컬에서만 문서를 연다.
        docs_url=f"{API_PREFIX}/docs" if settings.docs_enabled else None,
        openapi_url=f"{API_PREFIX}/openapi.json" if settings.docs_enabled else None,
        redoc_url=None,
    )
    app.state.settings = settings
    app.state.rate_limiter = SlidingWindowRateLimiter()
    app.add_middleware(RequestContextMiddleware)
    register_error_handlers(app)
    for router in (health_router, auth_router, users_router):
        app.include_router(router, prefix=API_PREFIX)
    return app
