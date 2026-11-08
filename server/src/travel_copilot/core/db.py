"""DB 엔진, 세션, 모델 베이스."""

from collections.abc import AsyncIterator

from fastapi import Request
from sqlalchemy import MetaData
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from travel_copilot.core.config import Settings

# 제약 조건 이름을 고정해서 Alembic 자동 생성 결과가 환경마다 달라지지 않게 한다.
NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}

# DB 연결이 안 될 때 요청이 오래 붙잡혀 있지 않게 한다.
CONNECT_TIMEOUT_SECONDS = 5


class Base(DeclarativeBase):
    """모든 SQLAlchemy 모델의 베이스."""

    metadata = MetaData(naming_convention=NAMING_CONVENTION)


def create_engine(settings: Settings) -> AsyncEngine:
    """설정으로 비동기 DB 엔진을 만든다.

    Args:
        settings: DB 주소가 들어 있는 서버 설정.

    Returns:
        연결 풀을 가진 비동기 엔진. 실제 연결은 처음 쓸 때 맺는다.
    """
    return create_async_engine(
        settings.database_url.get_secret_value(),
        pool_pre_ping=True,
        connect_args={"timeout": CONNECT_TIMEOUT_SECONDS},
    )


def create_sessionmaker(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    """엔진에 묶인 세션 팩토리를 만든다.

    Args:
        engine: 세션이 사용할 엔진.

    Returns:
        커밋 후에도 객체 속성을 다시 읽지 않는 세션 팩토리.
    """
    return async_sessionmaker(engine, expire_on_commit=False)


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    """요청마다 DB 세션을 하나 주는 FastAPI 의존성.

    Args:
        request: 현재 요청. 앱 상태에 저장된 세션 팩토리를 꺼내는 데 쓴다.

    Yields:
        요청이 끝나면 닫히는 세션.
    """
    sessionmaker: async_sessionmaker[AsyncSession] = request.app.state.sessionmaker
    async with sessionmaker() as session:
        yield session
