"""일정 항목 API (features/itinerary.md 6.1).

쓰기 요청은 모두 여행 행을 잠그고 처리한다 (position이 겹치지 않게, 5.3).
"""

import uuid
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.auth.dependencies import CurrentUser
from travel_copilot.core.db import get_session
from travel_copilot.itinerary import service
from travel_copilot.itinerary.schemas import (
    DayItems,
    ItemCreate,
    ItemRead,
    ItemUpdate,
    ReorderRequest,
)
from travel_copilot.itinerary.service import PlaceLocator
from travel_copilot.trips.dependencies import TripEditorLocked

router = APIRouter(prefix="/trips/{trip_id}", tags=["itinerary"])

Session = Annotated[AsyncSession, Depends(get_session)]


def get_place_locator(request: Request) -> PlaceLocator:
    """좌표 찾기 도구. Places 키가 없어도 만들 수 있다 (장소 없는 항목은 키 없이 동작)."""
    return PlaceLocator(
        cache=request.app.state.location_cache, client=request.app.state.places_client
    )


Locator = Annotated[PlaceLocator, Depends(get_place_locator)]


@router.post("/items", status_code=status.HTTP_201_CREATED)
async def create_item(
    body: ItemCreate,
    access: TripEditorLocked,
    user: CurrentUser,
    session: Session,
    locator: Locator,
) -> ItemRead:
    """일정 항목을 그날 맨 뒤에 추가한다."""
    return await service.create_item(session, access, user.id, body, locator)


@router.patch("/items/{item_id}")
async def update_item(
    item_id: uuid.UUID,
    body: ItemUpdate,
    access: TripEditorLocked,
    user: CurrentUser,
    session: Session,
    locator: Locator,
) -> ItemRead:
    """일정 항목을 고친다. version이 다르면 409."""
    return await service.update_item(session, access, user.id, item_id, body, locator)


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(
    item_id: uuid.UUID,
    access: TripEditorLocked,
    session: Session,
    version: Annotated[int, Query(ge=1)],
) -> Response:
    """일정 항목을 지운다. version이 다르면 409."""
    await service.delete_item(session, access, item_id, version)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.put("/days/{day}/order")
async def reorder_day(
    day: date, body: ReorderRequest, access: TripEditorLocked, user: CurrentUser, session: Session
) -> DayItems:
    """하루 순서를 바꾼다. 그날의 모든 항목이 정확히 들어 있어야 한다."""
    return await service.reorder_day(session, access, user.id, day, body)
