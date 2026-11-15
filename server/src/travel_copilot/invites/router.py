"""초대 API (features/invites.md 6절).

`/trips/{trip_id}/invites...`는 owner 권한 확인 의존성을 쓴다 (라우트 전수 검사 대상).
"""

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.auth.dependencies import CurrentUser, get_settings
from travel_copilot.core.config import Settings
from travel_copilot.core.db import get_session
from travel_copilot.invites import service
from travel_copilot.invites.dependencies import redeem_rate_limit
from travel_copilot.invites.schemas import (
    InviteAccepted,
    InviteCreate,
    InviteCreated,
    InviteList,
    InvitePreview,
    InviteToken,
    RevokeAllResult,
)
from travel_copilot.trips.dependencies import TripOwner, TripOwnerLocked

router = APIRouter(tags=["invites"])

Session = Annotated[AsyncSession, Depends(get_session)]
AppSettings = Annotated[Settings, Depends(get_settings)]


@router.post("/trips/{trip_id}/invites", status_code=status.HTTP_201_CREATED)
async def create_invite(
    access: TripOwnerLocked,
    session: Session,
    settings: AppSettings,
    body: InviteCreate | None = None,
) -> InviteCreated:
    """초대 링크를 만든다 (owner). 토큰이 담긴 url은 이 응답에서만 나온다."""
    return await service.create_invite(
        session, access, body or InviteCreate(), settings.invite_base_url
    )


@router.get("/trips/{trip_id}/invites")
async def list_invites(access: TripOwner, session: Session) -> InviteList:
    """초대 링크 목록 (owner). 토큰은 없다."""
    return await service.list_invites(session, access)


@router.delete("/trips/{trip_id}/invites/{invite_id}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_invite(invite_id: uuid.UUID, access: TripOwner, session: Session) -> Response:
    """링크를 폐기한다 (owner)."""
    await service.revoke_invite(session, access, invite_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/trips/{trip_id}/invites/revoke-all")
async def revoke_all_invites(access: TripOwnerLocked, session: Session) -> RevokeAllResult:
    """열린 링크를 모두 폐기한다 (owner)."""
    return await service.revoke_all(session, access)


@router.post("/invites/preview", dependencies=[Depends(redeem_rate_limit)])
async def preview_invite(body: InviteToken, user: CurrentUser, session: Session) -> InvitePreview:
    """참여 확인 화면용 정보. 사용 횟수는 쓰지 않는다."""
    return await service.preview(session, user.id, body.token)


@router.post("/invites/accept", dependencies=[Depends(redeem_rate_limit)])
async def accept_invite(body: InviteToken, user: CurrentUser, session: Session) -> InviteAccepted:
    """링크로 여행에 참여한다."""
    return await service.accept(session, user.id, body.token)
