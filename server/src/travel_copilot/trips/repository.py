"""여행 DB 접근. 커밋은 서비스가 한다."""

import uuid
from dataclasses import dataclass
from datetime import date
from typing import Any

from sqlalchemy import delete, func, select, tuple_, update
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.trips.models import Trip, TripMember, TripRole
from travel_copilot.users.models import User


@dataclass(frozen=True, slots=True)
class TripWithRole:
    """요청자 기준으로 읽은 여행."""

    trip: Trip
    my_role: TripRole
    member_count: int


def _member_count() -> Any:
    return (
        select(func.count())
        .where(TripMember.trip_id == Trip.id)
        .correlate(Trip)
        .scalar_subquery()
        .label("member_count")
    )


async def get_membership(
    session: AsyncSession, trip_id: uuid.UUID, user_id: uuid.UUID
) -> TripMember | None:
    """한 사용자의 여행 멤버십을 DB에서 새로 읽는다.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        user_id: 사용자 ID.

    Returns:
        멤버십. 멤버가 아니면 None.
    """
    result = await session.execute(
        select(TripMember)
        .where(TripMember.trip_id == trip_id, TripMember.user_id == user_id)
        # 세션에 남은 예전 값이 아니라 DB의 현재 값을 쓴다 (잠금 후 다시 읽는 경우)
        .execution_options(populate_existing=True)
    )
    return result.scalar_one_or_none()


async def get_trip(session: AsyncSession, trip_id: uuid.UUID, *, lock: bool = False) -> Trip | None:
    """여행을 읽는다.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        lock: True면 트랜잭션이 끝날 때까지 여행 행을 잠근다 (`FOR UPDATE`).
            멤버 구성을 바꾸는 작업은 모두 이 잠금을 먼저 잡아 순서대로 처리한다.

    Returns:
        여행. 없으면 None.
    """
    statement = select(Trip).where(Trip.id == trip_id).execution_options(populate_existing=True)
    if lock:
        statement = statement.with_for_update()
    result = await session.execute(statement)
    return result.scalar_one_or_none()


async def count_members(session: AsyncSession, trip_id: uuid.UUID) -> int:
    """여행 멤버 수를 센다.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.

    Returns:
        멤버 수.
    """
    result = await session.execute(
        select(func.count()).select_from(TripMember).where(TripMember.trip_id == trip_id)
    )
    return result.scalar_one()


async def list_for_user(
    session: AsyncSession,
    user_id: uuid.UUID,
    limit: int,
    after: tuple[date, uuid.UUID] | None,
) -> list[TripWithRole]:
    """사용자가 멤버인 여행을 최근 시작일 순으로 읽는다.

    Args:
        session: DB 세션.
        user_id: 사용자 ID.
        limit: 최대 개수.
        after: 이전 페이지 마지막 항목의 (시작일, ID). 이 항목 다음부터 읽는다.

    Returns:
        여행과 내 역할, 멤버 수.
    """
    statement = (
        select(Trip, TripMember.role, _member_count())
        .join(TripMember, TripMember.trip_id == Trip.id)
        .where(TripMember.user_id == user_id)
        .order_by(Trip.start_date.desc(), Trip.id.desc())
        .limit(limit)
    )
    if after is not None:
        statement = statement.where(tuple_(Trip.start_date, Trip.id) < tuple_(*after))
    rows = (await session.execute(statement)).all()
    return [TripWithRole(trip=row[0], my_role=row[1], member_count=row[2]) for row in rows]


async def list_members(session: AsyncSession, trip_id: uuid.UUID) -> list[tuple[TripMember, str]]:
    """여행 멤버를 참여 순으로 읽는다.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.

    Returns:
        (멤버십, 표시 이름) 행 목록.
    """
    result = await session.execute(
        select(TripMember, User.display_name)
        .join(User, User.id == TripMember.user_id)
        .where(TripMember.trip_id == trip_id)
        .order_by(TripMember.joined_at, TripMember.user_id)
    )
    return [(row[0], row[1]) for row in result.all()]


async def get_display_name(session: AsyncSession, user_id: uuid.UUID) -> str:
    """사용자의 표시 이름을 읽는다.

    Args:
        session: DB 세션.
        user_id: 사용자 ID (존재가 확인된 사용자).

    Returns:
        표시 이름.
    """
    result = await session.execute(select(User.display_name).where(User.id == user_id))
    return result.scalar_one()


async def create_trip(
    session: AsyncSession, owner_id: uuid.UUID, values: dict[str, Any]
) -> tuple[Trip, TripMember]:
    """여행과 owner 멤버십을 만든다.

    Args:
        session: DB 세션.
        owner_id: 여행을 만든 사용자 ID.
        values: 여행 컬럼 값 (검증 완료).

    Returns:
        DB에 반영(flush)된 여행과 owner 멤버십.
    """
    trip = Trip(**values)
    session.add(trip)
    await session.flush()
    member = TripMember(trip_id=trip.id, user_id=owner_id, role=TripRole.OWNER)
    session.add(member)
    await session.flush()
    await session.refresh(trip)
    await session.refresh(member)
    return trip, member


async def update_trip_if_version(
    session: AsyncSession, trip_id: uuid.UUID, version: int, values: dict[str, Any]
) -> Trip | None:
    """version이 맞을 때만 여행을 고치고 version을 1 올린다.

    확인과 수정을 UPDATE 한 문장으로 해서, 읽고 비교한 뒤 쓰는 사이에
    다른 수정이 끼어들 틈을 없앤다 (T29).

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        version: 요청자가 본 version.
        values: 바꿀 컬럼 값.

    Returns:
        고친 여행. version이 달라서 고치지 않았으면 None.
    """
    result = await session.execute(
        update(Trip)
        .where(Trip.id == trip_id, Trip.version == version)
        .values(**values, version=Trip.version + 1)
        .returning(Trip)
        .execution_options(synchronize_session=False, populate_existing=True)
    )
    return result.scalar_one_or_none()


async def delete_trip(session: AsyncSession, trip_id: uuid.UUID) -> None:
    """여행을 지운다. 멤버는 FK의 ON DELETE CASCADE로 같이 지워진다.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
    """
    await session.execute(delete(Trip).where(Trip.id == trip_id))


async def delete_membership(session: AsyncSession, trip_id: uuid.UUID, user_id: uuid.UUID) -> None:
    """멤버십을 지운다.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        user_id: 내보내거나 나가는 사용자 ID.
    """
    await session.execute(
        delete(TripMember).where(TripMember.trip_id == trip_id, TripMember.user_id == user_id)
    )
