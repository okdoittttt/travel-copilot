"""초대 업무 규칙 (features/invites.md 5절)."""

import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.core.errors import NotFound
from travel_copilot.invites import repository, tokens
from travel_copilot.invites.errors import (
    AlreadyMember,
    InviteExhausted,
    InviteExpired,
    InviteGone,
    InviteLimit,
    InviteRevoked,
    TripMemberLimit,
)
from travel_copilot.invites.models import Invite
from travel_copilot.invites.schemas import (
    InviteAccepted,
    InviteCreate,
    InviteCreated,
    InviteList,
    InvitePreview,
    InviteRead,
    InviteStatus,
    RevokeAllResult,
)
from travel_copilot.trips import repository as trip_repository
from travel_copilot.trips.dependencies import TripAccess
from travel_copilot.trips.models import TripMember, TripRole

MAX_OPEN_INVITES = 5
MAX_TRIP_MEMBERS = 20


def _now() -> datetime:
    return datetime.now(UTC)


def invite_status(invite: Invite, now: datetime) -> InviteStatus:
    """링크 상태를 계산한다. 여러 이유가 겹치면 폐기 → 만료 → 소진 순으로 고른다.

    Args:
        invite: 초대.
        now: 기준 시각.

    Returns:
        상태.
    """
    if invite.revoked_at is not None:
        return InviteStatus.REVOKED
    if invite.expires_at <= now:
        return InviteStatus.EXPIRED
    if invite.use_count >= invite.max_uses:
        return InviteStatus.EXHAUSTED
    return InviteStatus.ACTIVE


_GONE_ERRORS: dict[InviteStatus, type[InviteGone]] = {
    InviteStatus.REVOKED: InviteRevoked,
    InviteStatus.EXPIRED: InviteExpired,
    InviteStatus.EXHAUSTED: InviteExhausted,
}


def _raise_if_ended(invite: Invite, now: datetime) -> None:
    status = invite_status(invite, now)
    if status is not InviteStatus.ACTIVE:
        raise _GONE_ERRORS[status]


def _read(invite: Invite, creator_name: str | None, now: datetime) -> InviteRead:
    return InviteRead(
        id=invite.id,
        role=invite.role,
        max_uses=invite.max_uses,
        use_count=invite.use_count,
        expires_at=invite.expires_at,
        revoked_at=invite.revoked_at,
        created_at=invite.created_at,
        created_by_name=creator_name,
        status=invite_status(invite, now),
    )


def invite_url(base_url: str, token: str) -> str:
    """초대 링크 주소. 토큰은 fragment(`#` 뒤)에 넣는다 (features/invites.md 5.2).

    Args:
        base_url: 설정의 `INVITE_BASE_URL` (끝 `/` 없음).
        token: 토큰 원문.

    Returns:
        `https://<도메인>/invite#<토큰>`.
    """
    return f"{base_url}/invite#{token}"


# --- owner의 링크 관리 --------------------------------------------------------


async def create_invite(
    session: AsyncSession, access: TripAccess, body: InviteCreate, base_url: str
) -> InviteCreated:
    """초대 링크를 만든다.

    Args:
        session: DB 세션.
        access: 권한 확인(owner, 여행 행 잠금)을 통과한 요청 정보.
        body: 검증된 요청.
        base_url: 링크 기본 주소.

    Returns:
        만든 링크. `url`(토큰 포함)은 이 응답에서만 나온다.

    Raises:
        InviteLimit: 열린 링크가 이미 5개일 때.
    """
    now = _now()
    # 여행 행을 잠근 상태라 세는 것과 만드는 것 사이에 다른 링크가 끼어들지 않는다
    if await repository.count_open(session, access.trip.id, now) >= MAX_OPEN_INVITES:
        raise InviteLimit
    token = tokens.new_token()
    invite = await repository.create(
        session,
        Invite(
            trip_id=access.trip.id,
            token_hash=tokens.hash_token(token),
            role=body.role,
            max_uses=body.max_uses,
            use_count=0,
            expires_at=now + timedelta(days=body.expires_in_days),
            created_by=access.membership.user_id,
        ),
    )
    creator_name = await trip_repository.get_display_name(session, access.membership.user_id)
    read = _read(invite, creator_name, now)
    await session.commit()
    return InviteCreated(**read.model_dump(), url=invite_url(base_url, token))


async def list_invites(session: AsyncSession, access: TripAccess) -> InviteList:
    """여행의 링크 목록 (토큰 없음).

    Args:
        session: DB 세션.
        access: 권한 확인(owner)을 통과한 요청 정보.

    Returns:
        링크 목록.
    """
    now = _now()
    rows = await repository.list_for_trip(session, access.trip.id, now)
    return InviteList(items=[_read(invite, name, now) for invite, name in rows])


async def revoke_invite(session: AsyncSession, access: TripAccess, invite_id: uuid.UUID) -> None:
    """링크 하나를 폐기한다. 이미 끝난 링크여도 성공으로 본다.

    Args:
        session: DB 세션.
        access: 권한 확인(owner)을 통과한 요청 정보.
        invite_id: 초대 ID.

    Raises:
        NotFound: 이 여행의 초대가 아닐 때.
    """
    invite = await repository.get_in_trip(session, access.trip.id, invite_id)
    if invite is None:
        raise NotFound
    await repository.revoke(session, invite.id, _now())
    await session.commit()


async def revoke_all(session: AsyncSession, access: TripAccess) -> RevokeAllResult:
    """열린 링크를 모두 폐기한다 (멤버를 내보낼 때 함께 쓴다, 5.6).

    Args:
        session: DB 세션.
        access: 권한 확인(owner)을 통과한 요청 정보.

    Returns:
        폐기한 수.
    """
    count = await repository.revoke_open(session, access.trip.id, _now())
    await session.commit()
    return RevokeAllResult(revoked=count)


# --- 받은 사람의 미리보기·참여 -----------------------------------------------


async def _find(session: AsyncSession, token: str) -> Invite:
    # 형식이 틀린 토큰도 없는 토큰과 같은 응답 (무엇이 틀렸는지 알려주지 않는다)
    if not tokens.is_well_formed(token):
        raise NotFound
    invite = await repository.get_by_token_hash(session, tokens.hash_token(token))
    if invite is None:
        raise NotFound
    return invite


async def preview(session: AsyncSession, user_id: uuid.UUID, token: str) -> InvitePreview:
    """참여 확인 화면용 최소 정보를 돌려준다. 사용 횟수는 쓰지 않는다.

    Args:
        session: DB 세션.
        user_id: 요청자 ID.
        token: 토큰 원문.

    Returns:
        미리보기. 이미 멤버면 `already_member`와 `trip_id`가 채워진다.

    Raises:
        NotFound: 토큰이 없거나 형식이 틀릴 때.
        InviteGone: 링크가 끝났을 때 (이미 멤버면 끝난 링크여도 미리보기를 준다).
    """
    invite = await _find(session, token)
    trip = await trip_repository.get_trip(session, invite.trip_id)
    if trip is None:
        raise NotFound
    member = await trip_repository.get_membership(session, trip.id, user_id)
    if member is None:
        _raise_if_ended(invite, _now())
    inviter = (
        await trip_repository.get_display_name(session, invite.created_by)
        if invite.created_by is not None
        else None
    )
    return InvitePreview(
        trip_title=trip.title,
        start_date=trip.start_date,
        end_date=trip.end_date,
        inviter_name=inviter,
        role=invite.role,
        already_member=member is not None,
        trip_id=trip.id if member is not None else None,
    )


async def accept(session: AsyncSession, user_id: uuid.UUID, token: str) -> InviteAccepted:
    """링크로 여행에 참여한다 (features/invites.md 5.3).

    Args:
        session: DB 세션.
        user_id: 요청자 ID.
        token: 토큰 원문.

    Returns:
        참여한 여행 ID.

    Raises:
        NotFound: 토큰이 없거나 형식이 틀릴 때.
        AlreadyMember: 이미 멤버일 때 (사용 횟수를 쓰지 않는다).
        TripMemberLimit: 멤버가 20명일 때.
        InviteGone: 링크가 끝났을 때.
    """
    invite = await _find(session, token)
    invite_id, trip_id, role = invite.id, invite.trip_id, invite.role
    # 멤버 구성을 바꾸는 다른 작업과 같은 순서로 여행 행부터 잠근다 (F2)
    trip = await trip_repository.get_trip(session, trip_id, lock=True)
    if trip is None:
        raise NotFound
    if await trip_repository.get_membership(session, trip_id, user_id) is not None:
        raise AlreadyMember
    if await trip_repository.count_members(session, trip_id) >= MAX_TRIP_MEMBERS:
        raise TripMemberLimit
    now = _now()
    if not await repository.use_once(session, invite_id, now):
        current = await repository.get_by_token_hash(session, tokens.hash_token(token))
        if current is None:
            raise NotFound
        _raise_if_ended(current, now)
        raise InviteExhausted  # 위에서 못 올렸으니 끝난 상태여야 한다 (방어)
    session.add(TripMember(trip_id=trip_id, user_id=user_id, role=TripRole(role.value)))
    await session.commit()
    return InviteAccepted(trip_id=trip_id)
