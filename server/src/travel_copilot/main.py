"""FastAPI 앱 생성."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from travel_copilot.core.config import Settings, get_settings
from travel_copilot.core.db import create_engine, create_sessionmaker
from travel_copilot.core.errors import register_error_handlers
from travel_copilot.core.logging import configure_logging
from travel_copilot.core.middleware import RequestContextMiddleware
from travel_copilot.health.router import router as health_router

API_PREFIX = "/api/v1"


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
    app.add_middleware(RequestContextMiddleware)
    register_error_handlers(app)
    app.include_router(health_router, prefix=API_PREFIX)
    return app
