"""서버 상태 확인 API."""

import asyncio
from typing import Annotated, Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.core.db import get_session
from travel_copilot.core.errors import ServiceUnavailable

router = APIRouter(tags=["health"])

DB_CHECK_TIMEOUT_SECONDS = 2


class HealthRead(BaseModel):
    """상태 확인 응답."""

    status: Literal["ok"]


@router.get("/health")
async def get_health(session: Annotated[AsyncSession, Depends(get_session)]) -> HealthRead:
    """서버와 DB가 요청을 처리할 수 있는지 확인한다."""
    # 버전·호스트·DB 정보는 응답에 넣지 않는다.
    try:
        await asyncio.wait_for(session.execute(text("SELECT 1")), DB_CHECK_TIMEOUT_SECONDS)
    except Exception as exc:
        raise ServiceUnavailable from exc
    return HealthRead(status="ok")
