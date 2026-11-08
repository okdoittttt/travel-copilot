"""Alembic 마이그레이션 실행 환경 (비동기)."""

import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from travel_copilot.core.config import get_settings
from travel_copilot.core.db import Base

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# DB 주소는 서버와 같은 설정(환경변수)에서 읽는다. alembic.ini에 비밀값을 두지 않기 위해서다.
database_url = get_settings().database_url.get_secret_value()

# 기능별 모델을 여기서 import해야 자동 생성이 테이블을 인식한다. (F1부터 추가)
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
