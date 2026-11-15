"""하루 일정 + 이동 구간 계산 (features/routes-map.md 5.1~5.3).

이동시간은 저장하지 않고 요청마다 Google Routes로 계산한다 (Google 약관).
"""

import asyncio
import itertools
import logging
import uuid
from datetime import UTC, date, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.core.errors import AppError
from travel_copilot.directions.client import GoogleRoutesClient
from travel_copilot.itinerary import repository
from travel_copilot.itinerary.models import ItineraryItem
from travel_copilot.itinerary.schemas import DayView, LegStatus, RouteLeg
from travel_copilot.itinerary.service import (
    LOCATION_MAX_AGE,
    PlaceLocator,
    check_day,
    item_read,
)
from travel_copilot.trips.dependencies import TripAccess

logger = logging.getLogger(__name__)

# 한 요청에서 Google을 동시에 부르는 최대 수 (T23)
MAX_CONCURRENT_CALLS = 5


def _needs_location(item: ItineraryItem, now: datetime) -> bool:
    if item.google_place_id is None:
        return False
    return item.location_fetched_at is None or now - item.location_fetched_at >= LOCATION_MAX_AGE


async def _refresh_locations(
    session: AsyncSession,
    items: list[ItineraryItem],
    user_id: uuid.UUID,
    locator: PlaceLocator,
    semaphore: asyncio.Semaphore,
) -> bool:
    """좌표가 없거나 30일 지난 항목의 좌표를 다시 받아 저장한다. 실패한 항목은 그대로 둔다.

    Returns:
        하나라도 갱신했으면 True.
    """
    now = datetime.now(UTC)
    targets = [item for item in items if _needs_location(item, now)]

    async def fetch(item: ItineraryItem) -> tuple[ItineraryItem, str, float, float] | None:
        place_id = item.google_place_id
        if place_id is None:
            return None
        async with semaphore:
            try:
                location = await locator.locate(user_id, place_id)
            except AppError:
                return None
        return item, place_id, location.lat, location.lng

    results = [r for r in await asyncio.gather(*(fetch(i) for i in targets)) if r is not None]
    for item, place_id, lat, lng in results:
        await repository.update_location_if_place(session, item.id, place_id, lat, lng, now)
    if results:
        await session.commit()
    return bool(results)


async def _compute_leg(
    origin: ItineraryItem,
    destination: ItineraryItem,
    client: GoogleRoutesClient | None,
    semaphore: asyncio.Semaphore,
) -> RouteLeg:
    mode = destination.travel_mode  # "이전 항목에서 이 항목까지" (F3 정의)
    leg = RouteLeg(
        from_item_id=origin.id, to_item_id=destination.id, mode=mode, status=LegStatus.UNAVAILABLE
    )
    if origin.google_place_id is None or destination.google_place_id is None:
        return leg.model_copy(update={"status": LegStatus.NO_LOCATION})
    if mode is None:
        return leg.model_copy(update={"status": LegStatus.NO_MODE})
    if client is None:
        return leg
    async with semaphore:
        try:
            result = await client.compute(origin.google_place_id, destination.google_place_id, mode)
        except AppError:
            return leg
    if result is None:
        return leg
    return leg.model_copy(
        update={
            "status": LegStatus.OK,
            "duration_seconds": result.duration_seconds,
            "distance_meters": result.distance_meters,
        }
    )


async def day_view(
    session: AsyncSession,
    access: TripAccess,
    user_id: uuid.UUID,
    day: date,
    locator: PlaceLocator,
    routes: GoogleRoutesClient | None,
) -> DayView:
    """하루 일정과 이동 구간을 돌려준다.

    Google 호출이 실패해도 일정은 정상으로 돌려주고, 해당 구간만 `unavailable`이다.

    Args:
        session: DB 세션.
        access: 권한 확인(viewer 이상)을 통과한 요청 정보.
        user_id: 요청자 ID (좌표 캐시 키).
        day: 현지 날짜.
        locator: 좌표 찾기 도구 (Places).
        routes: Routes 클라이언트. 키가 없으면 None → 모든 구간 unavailable.

    Returns:
        하루 일정 + 이동 구간.

    Raises:
        DayOutOfRange: 날짜가 여행 기간 밖일 때.
    """
    check_day(access, day)
    semaphore = asyncio.Semaphore(MAX_CONCURRENT_CALLS)
    items = await repository.list_day(session, access.trip.id, day)
    if await _refresh_locations(session, items, user_id, locator, semaphore):
        items = await repository.list_day(session, access.trip.id, day)

    legs = await asyncio.gather(
        *(_compute_leg(a, b, routes, semaphore) for a, b in itertools.pairwise(items))
    )
    now = datetime.now(UTC)
    return DayView(date=day, items=[item_read(item, now) for item in items], legs=list(legs))
