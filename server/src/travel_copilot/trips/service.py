"""여행·멤버 업무 규칙."""

import base64
import binascii
import json
import uuid
from datetime import date

from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.core.errors import AppError, Forbidden, NotFound, VersionConflict
from travel_copilot.trips import repository
from travel_copilot.trips.dependencies import TripAccess
from travel_copilot.trips.errors import (
    InvalidCursor,
    OwnerCannotLeave,
    OwnerRoleLocked,
    TripPeriodInvalid,
)
from travel_copilot.trips.models import Trip, TripMember, TripRole
from travel_copilot.trips.schemas import (
    MemberRead,
    TripCreate,
    TripList,
    TripRead,
    TripSnapshot,
    TripUpdate,
    period_is_valid,
)


def _trip_read(trip: Trip, my_role: TripRole, member_count: int) -> TripRead:
    return TripRead(
        id=trip.id,
        title=trip.title,
        destination=trip.destination,
        start_date=trip.start_date,
        end_date=trip.end_date,
        timezone=trip.timezone,
        version=trip.version,
        my_role=my_role,
        member_count=member_count,
        updated_at=trip.updated_at,
    )


def _member_read(member: TripMember, display_name: str) -> MemberRead:
    return MemberRead(
        user_id=member.user_id,
        display_name=display_name,
        role=member.role,
        joined_at=member.joined_at,
    )


# --- 목록 커서 ---------------------------------------------------------------


def encode_cursor(start_date: date, trip_id: uuid.UUID) -> str:
    """목록의 다음 페이지 위치를 불투명한 문자열로 만든다.

    Args:
        start_date: 마지막 항목의 시작일.
        trip_id: 마지막 항목의 ID.

    Returns:
        URL에 그대로 쓸 수 있는 커서.
    """
    raw = json.dumps({"d": start_date.isoformat(), "i": str(trip_id)}, separators=(",", ":"))
    return base64.urlsafe_b64encode(raw.encode()).decode().rstrip("=")


def decode_cursor(cursor: str) -> tuple[date, uuid.UUID]:
    """커서를 (시작일, ID)로 되돌린다.

    커서는 서명하지 않는다. 바꿔 보내도 자기가 멤버인 여행 안에서 위치만 달라질 뿐이라
    다른 사람의 데이터에 닿지 않는다. 형식만 엄격히 확인한다.

    Args:
        cursor: `encode_cursor`가 만든 문자열.

    Returns:
        (시작일, 여행 ID).

    Raises:
        InvalidCursor: 해석할 수 없을 때.
    """
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        data = json.loads(base64.urlsafe_b64decode(padded.encode()))
        return date.fromisoformat(data["d"]), uuid.UUID(data["i"])
    except (binascii.Error, ValueError, KeyError, TypeError, UnicodeDecodeError) as exc:
        raise InvalidCursor from exc


# --- 여행 --------------------------------------------------------------------


async def list_trips(
    session: AsyncSession, user_id: uuid.UUID, limit: int, cursor: str | None
) -> TripList:
    """내가 멤버인 여행 한 페이지를 돌려준다.

    Args:
        session: DB 세션.
        user_id: 요청자 ID.
        limit: 페이지 크기 (스키마에서 범위 검증 완료).
        cursor: 이전 응답의 `next_cursor`. 첫 페이지면 None.

    Returns:
        여행 목록과 다음 커서.
    """
    after = decode_cursor(cursor) if cursor else None
    # 하나 더 읽어서 다음 페이지가 있는지 판단한다
    rows = await repository.list_for_user(session, user_id, limit + 1, after)
    page = rows[:limit]
    next_cursor = (
        encode_cursor(page[-1].trip.start_date, page[-1].trip.id) if len(rows) > limit else None
    )
    return TripList(
        items=[_trip_read(row.trip, row.my_role, row.member_count) for row in page],
        next_cursor=next_cursor,
    )


async def create_trip(session: AsyncSession, user_id: uuid.UUID, body: TripCreate) -> TripRead:
    """여행을 만들고 요청자를 owner로 넣는다.

    Args:
        session: DB 세션.
        user_id: 요청자 ID.
        body: 검증된 요청.

    Returns:
        만든 여행.
    """
    trip, member = await repository.create_trip(session, user_id, body.model_dump())
    await session.commit()
    return _trip_read(trip, member.role, 1)


async def get_snapshot(session: AsyncSession, access: TripAccess) -> TripSnapshot:
    """여행 스냅샷(여행 정보 + 멤버)을 돌려준다.

    Args:
        session: DB 세션.
        access: 권한 확인을 통과한 요청 정보.

    Returns:
        스냅샷.
    """
    rows = await repository.list_members(session, access.trip.id)
    members = [_member_read(member, name) for member, name in rows]
    return TripSnapshot(trip=_trip_read(access.trip, access.role, len(members)), members=members)


async def _conflict(
    session: AsyncSession, trip_id: uuid.UUID, my_role: TripRole
) -> VersionConflict:
    """최신 여행 정보를 담은 409 예외를 만든다."""
    trip = await repository.get_trip(session, trip_id)
    if trip is None:
        return VersionConflict({})
    current = _trip_read(trip, my_role, await repository.count_members(session, trip_id))
    return VersionConflict(current.model_dump(mode="json"))


async def update_trip(session: AsyncSession, access: TripAccess, body: TripUpdate) -> TripRead:
    """여행 정보를 고친다.

    Args:
        session: DB 세션.
        access: 권한 확인(editor 이상)을 통과한 요청 정보.
        body: 바꿀 필드와 요청자가 본 version.

    Returns:
        고친 여행.

    Raises:
        VersionConflict: version이 서버 값과 다를 때. 최신 여행 정보를 담는다.
        TripPeriodInvalid: 기존 값과 합친 기간이 규칙에 맞지 않을 때.
    """
    # rollback 뒤에는 ORM 객체 속성을 읽을 수 없으므로 필요한 값을 먼저 꺼내 둔다
    trip_id, my_role = access.trip.id, access.role
    changes = body.changes()
    if body.version != access.trip.version:
        raise await _conflict(session, trip_id, my_role)
    start = changes.get("start_date", access.trip.start_date)
    end = changes.get("end_date", access.trip.end_date)
    if not period_is_valid(start, end):
        raise TripPeriodInvalid
    # TODO(F3): 기간이 줄어 밖으로 밀려나는 일정 항목이 있으면 409 (features/trips.md 4절)

    trip = await repository.update_trip_if_version(session, trip_id, body.version, changes)
    if trip is None:
        # 위에서 확인한 뒤 다른 요청이 먼저 고쳤다
        await session.rollback()
        raise await _conflict(session, trip_id, my_role)
    await session.commit()
    return _trip_read(trip, my_role, await repository.count_members(session, trip_id))


async def delete_trip(session: AsyncSession, access: TripAccess, version: int) -> None:
    """여행을 지운다.

    Args:
        session: DB 세션.
        access: 권한 확인(owner, 잠금)을 통과한 요청 정보.
        version: 요청자가 본 version.

    Raises:
        VersionConflict: version이 서버 값과 다를 때.
    """
    if version != access.trip.version:
        raise await _conflict(session, access.trip.id, access.role)
    # TODO(F7): 바우처 파일은 커밋 후 스토리지에서 삭제 (05-data-model 6절)
    await repository.delete_trip(session, access.trip.id)
    await session.commit()


# --- 멤버 --------------------------------------------------------------------


async def _target_member(
    session: AsyncSession, trip_id: uuid.UUID, user_id: uuid.UUID
) -> TripMember:
    member = await repository.get_membership(session, trip_id, user_id)
    if member is None:
        raise NotFound
    return member


async def change_role(
    session: AsyncSession, access: TripAccess, user_id: uuid.UUID, role: TripRole
) -> MemberRead:
    """멤버의 역할을 editor 또는 viewer로 바꾼다.

    Args:
        session: DB 세션.
        access: 권한 확인(owner, 잠금)을 통과한 요청 정보.
        user_id: 대상 사용자 ID.
        role: 새 역할 (스키마에서 editor·viewer만 허용).

    Returns:
        바뀐 멤버.

    Raises:
        NotFound: 대상이 이 여행의 멤버가 아닐 때.
        OwnerRoleLocked: 대상이 owner일 때.
    """
    member = await _target_member(session, access.trip.id, user_id)
    if member.role is TripRole.OWNER:
        raise OwnerRoleLocked
    member.role = role
    await session.commit()
    return _member_read(member, await repository.get_display_name(session, user_id))


async def remove_member(session: AsyncSession, access: TripAccess, user_id: uuid.UUID) -> None:
    """멤버를 내보내거나(owner), 스스로 나간다(본인).

    Args:
        session: DB 세션.
        access: 권한 확인(멤버, 잠금)을 통과한 요청 정보.
        user_id: 대상 사용자 ID.

    Raises:
        OwnerCannotLeave: owner가 자기 자신을 대상으로 했을 때.
        Forbidden: owner가 아닌 멤버가 다른 사람을 대상으로 했을 때.
        NotFound: 대상이 이 여행의 멤버가 아닐 때.
    """
    if user_id == access.membership.user_id:
        if access.role is TripRole.OWNER:
            raise OwnerCannotLeave
    else:
        if access.role is not TripRole.OWNER:
            raise Forbidden
        await _target_member(session, access.trip.id, user_id)
    # TODO(F7): 대상이 올린 바우처와 파일 삭제 (05-data-model 6절)
    await repository.delete_membership(session, access.trip.id, user_id)
    await session.commit()


async def transfer_ownership(
    session: AsyncSession, access: TripAccess, user_id: uuid.UUID
) -> TripSnapshot:
    """소유권을 다른 멤버에게 넘긴다. 기존 owner는 editor가 된다.

    Args:
        session: DB 세션.
        access: 권한 확인(owner, 잠금)을 통과한 요청 정보.
        user_id: 새 owner가 될 멤버의 사용자 ID.

    Returns:
        넘긴 뒤의 스냅샷 (요청자 기준).

    Raises:
        AppError: 자기 자신에게 넘기려 할 때 (400).
        NotFound: 대상이 이 여행의 멤버가 아닐 때.
    """
    if user_id == access.membership.user_id:
        raise AppError("이미 이 여행의 소유자입니다.")
    target = await _target_member(session, access.trip.id, user_id)

    # owner는 한 명만 가능하다는 DB 제약 때문에 순서가 중요하다: 먼저 낮추고 반영한 뒤 올린다
    access.membership.role = TripRole.EDITOR
    await session.flush()
    target.role = TripRole.OWNER
    await session.flush()
    await session.commit()
    return await get_snapshot(session, access)
