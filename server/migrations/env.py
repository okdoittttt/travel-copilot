"""Alembic 마이그레이션 실행 환경 (비동기)."""

import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

import travel_copilot.auth.models
import travel_copilot.users.models  # noqa: F401  # 테이블 등록용 import
from travel_copilot.core.config import DatabaseSettings
from travel_copilot.core.db import Base

config = context.config
if config.config_file_name is not None:
    # 테스트에서 마이그레이션을 돌릴 때 앱 로거가 꺼지지 않게 기존 로거를 유지한다
    fileConfig(config.config_file_name, disable_existing_loggers=False)

# DB 주소는 서버와 같은 설정(환경변수 DATABASE_URL)에서 읽는다. alembic.ini에 비밀값을 두지 않기
# 위해서다. 마이그레이션에는 DB 설정만 필요하므로 다른 서버 설정(JWT 키 등)은 요구하지 않는다.
database_url = DatabaseSettings().database_url.get_secret_value()  # type: ignore[call-arg]

# 기능별 모델 모듈을 위에서 import해야 자동 생성이 테이블을 인식한다.
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """DB에 연결하지 않고 SQL만 출력한다."""
    context.configure(
        url=database_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    """연결을 받아 마이그레이션을 실행한다."""
    context.configure(connection=connection, target_metadata=target_metadata, compare_type=True)
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """비동기 엔진으로 연결해서 마이그레이션을 실행한다."""
    connectable = async_engine_from_config(
        {"sqlalchemy.url": database_url},
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online() -> None:
    """DB에 연결해서 마이그레이션을 실행한다."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
