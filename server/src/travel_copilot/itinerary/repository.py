"""일정 항목 DB 접근. 커밋은 서비스가 한다.

항목은 항상 `trip_id`와 같이 조회한다. ID만으로 조회하지 않는다 (08-conventions S2, T06).
"""

import uuid
from datetime import date, datetime

from sqlalchemy import func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.itinerary.models import ItineraryItem


async def get_item(
    session: AsyncSession, trip_id: uuid.UUID, item_id: uuid.UUID
) -> ItineraryItem | None:
    """여행 안의 항목 하나를 읽는다.

    Args:
        session: DB 세션.
        trip_id: 권한 확인을 통과한 여행 ID.
        item_id: 항목 ID.

    Returns:
        항목. 없거나 다른 여행의 항목이면 None.
    """
    result = await session.execute(
        select(ItineraryItem).where(ItineraryItem.id == item_id, ItineraryItem.trip_id == trip_id)
    )
    return result.scalar_one_or_none()


async def list_day(session: AsyncSession, trip_id: uuid.UUID, day: date) -> list[ItineraryItem]:
    """하루 항목을 순서대로 읽는다.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        day: 현지 날짜.

    Returns:
        position 순 항목.
    """
    result = await session.execute(
        select(ItineraryItem)
        .where(ItineraryItem.trip_id == trip_id, ItineraryItem.day == day)
        .order_by(ItineraryItem.position)
        .execution_options(populate_existing=True)
    )
    return list(result.scalars())


async def list_trip(session: AsyncSession, trip_id: uuid.UUID) -> list[ItineraryItem]:
    """여행의 모든 항목을 날짜·순서대로 읽는다 (스냅샷용).

    Args:
        session: DB 세션.
        trip_id: 여행 ID.

    Returns:
        (day, position) 순 항목.
    """
    result = await session.execute(
        select(ItineraryItem)
        .where(ItineraryItem.trip_id == trip_id)
        .order_by(ItineraryItem.day, ItineraryItem.position)
    )
    return list(result.scalars())


async def count_day(session: AsyncSession, trip_id: uuid.UUID, day: date) -> int:
    """하루 항목 수를 센다.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        day: 현지 날짜.

    Returns:
        항목 수.
    """
    result = await session.execute(
        select(func.count())
        .select_from(ItineraryItem)
        .where(ItineraryItem.trip_id == trip_id, ItineraryItem.day == day)
    )
    return result.scalar_one()


async def count_outside(
    session: AsyncSession, trip_id: uuid.UUID, start: date, end: date
) -> dict[date, int]:
    """기간 밖에 있는 항목 수를 날짜별로 센다 (여행 기간 축소 검사용).

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        start: 새 시작일.
        end: 새 종료일.

    Returns:
        날짜 → 항목 수. 없으면 빈 dict.
    """
    result = await session.execute(
        select(ItineraryItem.day, func.count())
        .where(
            ItineraryItem.trip_id == trip_id,
            or_(ItineraryItem.day < start, ItineraryItem.day > end),
        )
        .group_by(ItineraryItem.day)
        .order_by(ItineraryItem.day)
    )
    return {row[0]: row[1] for row in result.all()}


async def clear_locations_before(session: AsyncSession, cutoff: datetime) -> int:
    """`cutoff`보다 먼저 받은 좌표를 지운다 (약관 30일 제한).

    Args:
        session: DB 세션.
        cutoff: 이 시각보다 오래된 좌표를 지운다.

    Returns:
        좌표를 지운 항목 수.
    """
    result = await session.execute(
        update(ItineraryItem)
        .where(ItineraryItem.location_fetched_at < cutoff)
        .values(lat=None, lng=None, location_fetched_at=None)
        .execution_options(synchronize_session=False)
    )
    return int(getattr(result, "rowcount", 0) or 0)
