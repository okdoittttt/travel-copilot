"""일정 항목 업무 규칙 (features/itinerary.md 5.2·5.3·5.4)."""

import uuid
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.core.errors import NotFound, VersionConflict
from travel_copilot.itinerary import repository
from travel_copilot.itinerary.errors import DayItemLimit, DayOutOfRange, OrderMismatch
from travel_copilot.itinerary.models import ItineraryItem
from travel_copilot.itinerary.schemas import (
    MAX_ITEMS_PER_DAY,
    DayItems,
    ItemCreate,
    ItemRead,
    ItemUpdate,
    ReorderRequest,
)
from travel_copilot.places.cache import LocationCache
from travel_copilot.places.client import GooglePlacesClient
from travel_copilot.places.errors import PlacesUnavailable
from travel_copilot.places.schemas import LatLng
from travel_copilot.trips.dependencies import TripAccess

# Google 약관: 좌표는 받은 지 30일까지만 (05-data-model 2절)
LOCATION_MAX_AGE = timedelta(days=30)


def _now() -> datetime:
    return datetime.now(UTC)


def item_read(item: ItineraryItem, now: datetime | None = None) -> ItemRead:
    """항목을 응답 형태로 바꾼다. 30일 지난 좌표는 넣지 않는다.

    Args:
        item: 항목.
        now: 기준 시각 (테스트용). 없으면 현재.

    Returns:
        응답 모델.
    """
    now = now or _now()
    location = None
    if (
        item.lat is not None
        and item.lng is not None
        and item.location_fetched_at is not None
        and now - item.location_fetched_at < LOCATION_MAX_AGE
    ):
        location = LatLng(lat=float(item.lat), lng=float(item.lng))
    return ItemRead(
        id=item.id,
        day=item.day,
        position=item.position,
        title=item.title,
        memo=item.memo,
        place_id=item.google_place_id,
        location=location,
        start_time=item.start_time,
        stay_minutes=item.stay_minutes,
        travel_mode=item.travel_mode,
        version=item.version,
        updated_at=item.updated_at,
    )


@dataclass(frozen=True, slots=True)
class PlaceLocator:
    """place_id의 좌표를 찾는다. 장소를 고를 때 받은 좌표(10분 기억)를 먼저 쓴다."""

    cache: LocationCache
    client: GooglePlacesClient | None

    async def locate(self, user_id: uuid.UUID, place_id: str) -> LatLng:
        """좌표를 찾는다. 앱이 보낸 좌표는 쓰지 않는다 (5.2).

        Args:
            user_id: 요청자 (캐시 키).
            place_id: Google 장소 ID (형식 검증 완료).

        Returns:
            Google에서 받은 좌표.

        Raises:
            PlacesUnavailable: 캐시에 없고 서버에 Places 키도 없을 때.
            UpstreamError: Google 호출이 실패했을 때.
        """
        cached = self.cache.get(user_id, place_id)
        if cached is not None:
            return cached
        if self.client is None:
            raise PlacesUnavailable
        details = await self.client.details(place_id, session_token=None)
        self.cache.put(user_id, place_id, details.location)
        return details.location


def _set_location(item: ItineraryItem, place_id: str | None, location: LatLng | None) -> None:
    item.google_place_id = place_id
    if location is None:
        item.lat = item.lng = None
        item.location_fetched_at = None
    else:
        item.lat = Decimal(str(round(location.lat, 6)))
        item.lng = Decimal(str(round(location.lng, 6)))
        item.location_fetched_at = _now()


def _check_day(access: TripAccess, day: date) -> None:
    if not access.trip.start_date <= day <= access.trip.end_date:
        raise DayOutOfRange


async def _check_day_capacity(session: AsyncSession, trip_id: uuid.UUID, day: date) -> int:
    count = await repository.count_day(session, trip_id, day)
    if count >= MAX_ITEMS_PER_DAY:
        raise DayItemLimit
    return count


async def _renumber(session: AsyncSession, trip_id: uuid.UUID, day: date) -> None:
    """빈자리를 당겨 0부터 다시 번호를 매긴다. UNIQUE는 커밋 때 검사한다."""
    for position, item in enumerate(await repository.list_day(session, trip_id, day)):
        if item.position != position:
            item.position = position


async def _day_items(session: AsyncSession, trip_id: uuid.UUID, day: date) -> DayItems:
    now = _now()
    items = await repository.list_day(session, trip_id, day)
    return DayItems(date=day, items=[item_read(item, now) for item in items])


async def list_items(session: AsyncSession, trip_id: uuid.UUID) -> list[ItemRead]:
    """스냅샷에 넣을 여행의 모든 항목.

    Args:
        session: DB 세션.
        trip_id: 권한 확인을 통과한 여행 ID.

    Returns:
        날짜·순서대로 정렬된 항목.
    """
    now = _now()
    return [item_read(item, now) for item in await repository.list_trip(session, trip_id)]


async def create_item(
    session: AsyncSession,
    access: TripAccess,
    user_id: uuid.UUID,
    body: ItemCreate,
    locator: PlaceLocator,
) -> ItemRead:
    """항목을 그날 맨 뒤에 추가한다.

    Args:
        session: DB 세션.
        access: 권한 확인(editor 이상, 여행 행 잠금)을 통과한 요청 정보.
        user_id: 요청자 ID.
        body: 검증된 요청.
        locator: 좌표를 찾을 도구.

    Returns:
        추가한 항목.

    Raises:
        DayOutOfRange: 날짜가 여행 기간 밖일 때.
        DayItemLimit: 그날 항목이 이미 50개일 때.
    """
    _check_day(access, body.day)
    position = await _check_day_capacity(session, access.trip.id, body.day)
    location = await locator.locate(user_id, body.place_id) if body.place_id else None
    item = ItineraryItem(
        trip_id=access.trip.id,
        day=body.day,
        position=position,
        title=body.title,
        memo=body.memo,
        start_time=body.start_time,
        stay_minutes=body.stay_minutes,
        travel_mode=body.travel_mode,
        created_by=user_id,
        updated_by=user_id,
    )
    _set_location(item, body.place_id, location)
    session.add(item)
    await session.commit()
    await session.refresh(item)
    return item_read(item)


async def _get_or_404(
    session: AsyncSession, trip_id: uuid.UUID, item_id: uuid.UUID
) -> ItineraryItem:
    item = await repository.get_item(session, trip_id, item_id)
    if item is None:
        raise NotFound
    return item


async def update_item(
    session: AsyncSession,
    access: TripAccess,
    user_id: uuid.UUID,
    item_id: uuid.UUID,
    body: ItemUpdate,
    locator: PlaceLocator,
) -> ItemRead:
    """항목을 고친다. `day`가 바뀌면 새 날 맨 뒤로 옮기고 원래 날의 번호를 당긴다.

    Args:
        session: DB 세션.
        access: 권한 확인(editor 이상, 여행 행 잠금)을 통과한 요청 정보.
        user_id: 요청자 ID.
        item_id: 항목 ID.
        body: 바꿀 필드와 version.
        locator: 좌표를 찾을 도구.

    Returns:
        고친 항목.

    Raises:
        NotFound: 이 여행의 항목이 아닐 때.
        VersionConflict: version이 다를 때. 최신 항목을 담는다.
        DayOutOfRange: 새 날짜가 여행 기간 밖일 때.
        DayItemLimit: 옮길 날의 항목이 이미 50개일 때.
    """
    item = await _get_or_404(session, access.trip.id, item_id)
    if body.version != item.version:
        raise VersionConflict(item_read(item).model_dump(mode="json"))
    changes = body.changes()

    old_day = item.day
    new_day = changes.pop("day", old_day)
    if new_day != old_day:
        _check_day(access, new_day)
        item.position = await _check_day_capacity(session, access.trip.id, new_day)
        item.day = new_day

    if "place_id" in changes:
        place_id = changes.pop("place_id")
        if place_id != item.google_place_id:
            location = await locator.locate(user_id, place_id) if place_id else None
            _set_location(item, place_id, location)

    for name, value in changes.items():
        setattr(item, name, value)
    item.version += 1
    item.updated_by = user_id
    await session.flush()
    if new_day != old_day:
        await _renumber(session, access.trip.id, old_day)
    await session.commit()
    await session.refresh(item)
    return item_read(item)


async def delete_item(
    session: AsyncSession, access: TripAccess, item_id: uuid.UUID, version: int
) -> None:
    """항목을 지우고 그날 번호를 당긴다.

    Args:
        session: DB 세션.
        access: 권한 확인(editor 이상, 여행 행 잠금)을 통과한 요청 정보.
        item_id: 항목 ID.
        version: 요청자가 본 version.

    Raises:
        NotFound: 이 여행의 항목이 아닐 때.
        VersionConflict: version이 다를 때.
    """
    item = await _get_or_404(session, access.trip.id, item_id)
    if version != item.version:
        raise VersionConflict(item_read(item).model_dump(mode="json"))
    day = item.day
    # TODO(F7): 연결된 바우처는 남기고 itinerary_item_id만 NULL (05-data-model 6절)
    await session.delete(item)
    await session.flush()
    await _renumber(session, access.trip.id, day)
    await session.commit()


async def reorder_day(
    session: AsyncSession,
    access: TripAccess,
    user_id: uuid.UUID,
    day: date,
    body: ReorderRequest,
) -> DayItems:
    """하루 순서를 바꾼다. 위치가 바뀐 항목만 version을 올린다.

    Args:
        session: DB 세션.
        access: 권한 확인(editor 이상, 여행 행 잠금)을 통과한 요청 정보.
        user_id: 요청자 ID.
        day: 현지 날짜.
        body: 새 순서대로의 항목 ID와 version.

    Returns:
        바뀐 그날 일정.

    Raises:
        OrderMismatch: 목록이 그날 항목과 정확히 같지 않을 때.
        VersionConflict: version이 하나라도 다를 때.
    """
    items = await repository.list_day(session, access.trip.id, day)
    by_id = {item.id: item for item in items}
    requested = [entry.id for entry in body.items]
    if len(requested) != len(set(requested)) or set(requested) != set(by_id):
        raise OrderMismatch(
            (await _day_items(session, access.trip.id, day)).model_dump(mode="json")
        )
    if any(by_id[entry.id].version != entry.version for entry in body.items):
        raise VersionConflict(
            (await _day_items(session, access.trip.id, day)).model_dump(mode="json")
        )

    for position, entry in enumerate(body.items):
        item = by_id[entry.id]
        if item.position != position:
            item.position = position
            item.version += 1
            item.updated_by = user_id
    await session.commit()
    return await _day_items(session, access.trip.id, day)
