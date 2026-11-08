"""내 정보 API."""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.auth.dependencies import CurrentUser
from travel_copilot.core.db import get_session
from travel_copilot.users import service
from travel_copilot.users.models import User
from travel_copilot.users.schemas import MeRead, MeUpdate

router = APIRouter(prefix="/me", tags=["me"])


def _me(user: User) -> MeRead:
    return MeRead(id=user.id, display_name=user.display_name, email=user.email)


@router.get("")
async def get_me(user: CurrentUser) -> MeRead:
    """로그인한 사용자의 정보를 돌려준다."""
    return _me(user)


@router.patch("")
async def update_me(
    body: MeUpdate,
    user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> MeRead:
    """표시 이름을 바꾼다."""
    return _me(await service.update_display_name(session, user, body.display_name))
