"""여행·멤버 API (features/trips.md 6절).

`{trip_id}`가 들어간 라우트는 모두 `trips.dependencies`의 권한 확인 의존성을 쓴다.
"""

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.auth.dependencies import CurrentUser
from travel_copilot.core.db import get_session
from travel_copilot.trips import service
from travel_copilot.trips.dependencies import (
    TripEditor,
    TripOwnerLocked,
    TripViewer,
    TripViewerLocked,
)
from travel_copilot.trips.schemas import (
    LIST_LIMIT_DEFAULT,
    LIST_LIMIT_MAX,
    MemberRead,
    MemberRoleUpdate,
    OwnershipTransfer,
    TripCreate,
    TripList,
    TripRead,
    TripSnapshot,
    TripUpdate,
)

router = APIRouter(prefix="/trips", tags=["trips"])

Session = Annotated[AsyncSession, Depends(get_session)]


@router.get("")
async def list_trips(
    user: CurrentUser,
    session: Session,
    cursor: Annotated[str | None, Query(max_length=200)] = None,
    limit: Annotated[int, Query(ge=1, le=LIST_LIMIT_MAX)] = LIST_LIMIT_DEFAULT,
) -> TripList:
    """내가 멤버인 여행 목록. 최근 시작일 순."""
    return await service.list_trips(session, user.id, limit, cursor)


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_trip(body: TripCreate, user: CurrentUser, session: Session) -> TripRead:
    """여행을 만든다. 만든 사람이 owner가 된다."""
    return await service.create_trip(session, user.id, body)


@router.get("/{trip_id}")
async def get_trip(access: TripViewer, session: Session) -> TripSnapshot:
    """여행 스냅샷 (여행 정보 + 멤버)."""
    return await service.get_snapshot(session, access)


@router.patch("/{trip_id}")
async def update_trip(body: TripUpdate, access: TripEditor, session: Session) -> TripRead:
    """여행 정보를 고친다. version이 다르면 409."""
    return await service.update_trip(session, access, body)


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_trip(
    access: TripOwnerLocked,
    session: Session,
    version: Annotated[int, Query(ge=1)],
) -> Response:
    """여행을 지운다 (owner). version이 다르면 409."""
    await service.delete_trip(session, access, version)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.patch("/{trip_id}/members/{user_id}")
async def change_member_role(
    user_id: uuid.UUID, body: MemberRoleUpdate, access: TripOwnerLocked, session: Session
) -> MemberRead:
    """멤버 역할을 editor ↔ viewer로 바꾼다 (owner)."""
    return await service.change_role(session, access, user_id, body.role)


@router.delete("/{trip_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_member(user_id: uuid.UUID, access: TripViewerLocked, session: Session) -> Response:
    """owner가 멤버를 내보내거나, 본인이 나간다."""
    await service.remove_member(session, access, user_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/{trip_id}/transfer-ownership")
async def transfer_ownership(
    body: OwnershipTransfer, access: TripOwnerLocked, session: Session
) -> TripSnapshot:
    """소유권을 다른 멤버에게 넘긴다 (owner). 나는 editor가 된다."""
    return await service.transfer_ownership(session, access, body.user_id)
