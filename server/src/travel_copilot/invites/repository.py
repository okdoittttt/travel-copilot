"""초대 DB 접근. 커밋은 서비스가 한다."""

import uuid
from datetime import datetime, timedelta

from sqlalchemy import ColumnElement, and_, delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.invites.models import Invite
from travel_copilot.users.models import User

# 만료된 지 이 기간이 지난 초대는 목록에서 빼고 정리 작업이 지운다
ENDED_RETENTION = timedelta(days=30)


def _is_open(now: datetime) -> ColumnElement[bool]:
    """폐기·만료·소진되지 않은 링크 조건."""
    return and_(
        Invite.revoked_at.is_(None), Invite.expires_at > now, Invite.use_count < Invite.max_uses
    )


async def count_open(session: AsyncSession, trip_id: uuid.UUID, now: datetime) -> int:
    """여행의 열린 링크 수.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        now: 기준 시각.

    Returns:
        열린 링크 수.
    """
    result = await session.execute(
        select(func.count()).select_from(Invite).where(Invite.trip_id == trip_id, _is_open(now))
    )
    return result.scalar_one()


async def create(session: AsyncSession, invite: Invite) -> Invite:
    """초대를 저장한다.

    Args:
        session: DB 세션.
        invite: 저장할 초대.

    Returns:
        DB 기본값이 채워진 초대.
    """
    session.add(invite)
    await session.flush()
    await session.refresh(invite)
    return invite


async def list_for_trip(
    session: AsyncSession, trip_id: uuid.UUID, now: datetime
) -> list[tuple[Invite, str | None]]:
    """여행의 링크를 최신순으로 읽는다. 만료된 지 30일이 지난 것은 뺀다.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        now: 기준 시각.

    Returns:
        (초대, 만든 사람 표시 이름) 목록. 만든 사람이 탈퇴했으면 이름은 None.
    """
    result = await session.execute(
        select(Invite, User.display_name)
        .outerjoin(User, User.id == Invite.created_by)
        .where(Invite.trip_id == trip_id, Invite.expires_at > now - ENDED_RETENTION)
        .order_by(Invite.created_at.desc(), Invite.id.desc())
    )
    return [(row[0], row[1]) for row in result.all()]


async def get_in_trip(
    session: AsyncSession, trip_id: uuid.UUID, invite_id: uuid.UUID
) -> Invite | None:
    """여행에 속한 초대 하나. 다른 여행의 초대 ID면 None.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        invite_id: 초대 ID.

    Returns:
        초대 또는 None.
    """
    result = await session.execute(
        select(Invite).where(Invite.id == invite_id, Invite.trip_id == trip_id)
    )
    return result.scalar_one_or_none()


async def get_by_token_hash(session: AsyncSession, token_hash: str) -> Invite | None:
    """토큰 해시로 초대를 찾는다.

    Args:
        session: DB 세션.
        token_hash: 토큰의 SHA-256.

    Returns:
        초대 또는 None.
    """
    result = await session.execute(
        select(Invite)
        .where(Invite.token_hash == token_hash)
        .execution_options(populate_existing=True)
    )
    return result.scalar_one_or_none()


async def use_once(session: AsyncSession, invite_id: uuid.UUID, now: datetime) -> bool:
    """열린 링크일 때만 사용 횟수를 1 올린다.

    확인과 증가를 UPDATE 한 문장으로 해서, 동시에 여러 명이 참여해도
    `max_uses`를 넘지 않는다 (T12).

    Args:
        session: DB 세션.
        invite_id: 초대 ID.
        now: 기준 시각.

    Returns:
        올렸으면 True, 링크가 끝나서 못 올렸으면 False.
    """
    result = await session.execute(
        update(Invite)
        .where(Invite.id == invite_id, _is_open(now))
        .values(use_count=Invite.use_count + 1)
        .returning(Invite.id)
        .execution_options(synchronize_session=False)
    )
    return result.scalar_one_or_none() is not None


async def revoke(session: AsyncSession, invite_id: uuid.UUID, now: datetime) -> None:
    """링크를 폐기한다. 이미 폐기됐으면 그대로 둔다.

    Args:
        session: DB 세션.
        invite_id: 초대 ID.
        now: 폐기 시각.
    """
    await session.execute(
        update(Invite)
        .where(Invite.id == invite_id, Invite.revoked_at.is_(None))
        .values(revoked_at=now)
        .execution_options(synchronize_session=False)
    )


async def revoke_open(session: AsyncSession, trip_id: uuid.UUID, now: datetime) -> int:
    """여행의 열린 링크를 모두 폐기한다.

    Args:
        session: DB 세션.
        trip_id: 여행 ID.
        now: 폐기 시각.

    Returns:
        폐기한 링크 수.
    """
    result = await session.execute(
        update(Invite)
        .where(Invite.trip_id == trip_id, _is_open(now))
        .values(revoked_at=now)
        .returning(Invite.id)
        .execution_options(synchronize_session=False)
    )
    return len(result.all())


async def purge_ended(session: AsyncSession, now: datetime) -> int:
    """만료된 지 30일이 지난 초대를 지운다 (폐기·소진된 링크도 결국 만료되므로 함께 지워진다).

    Args:
        session: DB 세션.
        now: 기준 시각.

    Returns:
        지운 행 수.
    """
    result = await session.execute(
        delete(Invite).where(Invite.expires_at <= now - ENDED_RETENTION).returning(Invite.id)
    )
    return len(result.all())
