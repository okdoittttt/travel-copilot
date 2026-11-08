"""로그인 관련 DB 접근."""

import uuid
from datetime import datetime

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.auth.models import AuthNonce, AuthProvider, RefreshToken, SocialAccount


async def find_user_id_by_social(
    session: AsyncSession, provider: AuthProvider, subject: str
) -> uuid.UUID | None:
    """소셜 계정으로 사용자 ID를 찾는다.

    Args:
        session: DB 세션.
        provider: 로그인 공급자.
        subject: 공급자의 사용자 ID (sub).

    Returns:
        연결된 사용자 ID. 없으면 None.
    """
    result = await session.execute(
        select(SocialAccount.user_id).where(
            SocialAccount.provider == provider, SocialAccount.subject == subject
        )
    )
    return result.scalar_one_or_none()


async def create_social_account(
    session: AsyncSession, user_id: uuid.UUID, provider: AuthProvider, subject: str
) -> None:
    """사용자와 소셜 계정을 연결한다.

    Args:
        session: DB 세션.
        user_id: 연결할 사용자.
        provider: 로그인 공급자.
        subject: 공급자의 사용자 ID (sub).
    """
    session.add(SocialAccount(user_id=user_id, provider=provider, subject=subject))
    await session.flush()


async def add_nonce(session: AsyncSession, nonce_hash: str, expires_at: datetime) -> None:
    """로그인용 nonce의 해시를 저장한다.

    Args:
        session: DB 세션.
        nonce_hash: nonce의 SHA-256 해시.
        expires_at: 만료 시각.
    """
    session.add(AuthNonce(nonce_hash=nonce_hash, expires_at=expires_at))


async def delete_expired_nonces(session: AsyncSession, now: datetime) -> None:
    """만료된 nonce를 지운다.

    Args:
        session: DB 세션.
        now: 현재 시각.
    """
    await session.execute(delete(AuthNonce).where(AuthNonce.expires_at <= now))


async def consume_nonce(session: AsyncSession, nonce_hash: str, now: datetime) -> bool:
    """만료 전 nonce를 지우면서 사용 처리한다.

    조회와 삭제를 한 문장으로 해서, 같은 nonce로 동시에 두 번 로그인해도 한 번만 성공한다.

    Args:
        session: DB 세션.
        nonce_hash: ID 토큰 안 nonce의 해시.
        now: 현재 시각.

    Returns:
        사용 가능한 nonce였으면 True.
    """
    result = await session.execute(
        delete(AuthNonce)
        .where(AuthNonce.nonce_hash == nonce_hash, AuthNonce.expires_at > now)
        .returning(AuthNonce.nonce_hash)
    )
    return result.scalar_one_or_none() is not None


async def add_refresh_token(
    session: AsyncSession,
    user_id: uuid.UUID,
    family_id: uuid.UUID,
    token_hash: str,
    expires_at: datetime,
) -> None:
    """리프레시 토큰 해시를 저장한다.

    Args:
        session: DB 세션.
        user_id: 토큰 주인.
        family_id: 토큰 묶음 ID.
        token_hash: 토큰의 SHA-256 해시.
        expires_at: 만료 시각.
    """
    session.add(
        RefreshToken(
            user_id=user_id, family_id=family_id, token_hash=token_hash, expires_at=expires_at
        )
    )


async def mark_refresh_token_used(
    session: AsyncSession, token_hash: str, now: datetime
) -> RefreshToken | None:
    """쓸 수 있는 리프레시 토큰이면 사용 처리하고 돌려준다.

    조건 확인과 갱신을 한 문장으로 해서, 같은 토큰으로 동시에 갱신해도 한 번만 성공한다.

    Args:
        session: DB 세션.
        token_hash: 토큰의 SHA-256 해시.
        now: 현재 시각.

    Returns:
        사용 처리된 토큰. 없거나·사용됐거나·폐기·만료됐으면 None.
    """
    result = await session.execute(
        update(RefreshToken)
        .where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.used_at.is_(None),
            RefreshToken.revoked_at.is_(None),
            RefreshToken.expires_at > now,
        )
        .values(used_at=now)
        .returning(RefreshToken)
    )
    return result.scalar_one_or_none()


async def find_refresh_token(session: AsyncSession, token_hash: str) -> RefreshToken | None:
    """해시로 리프레시 토큰을 찾는다 (상태와 무관).

    Args:
        session: DB 세션.
        token_hash: 토큰의 SHA-256 해시.

    Returns:
        토큰. 없으면 None.
    """
    result = await session.execute(
        select(RefreshToken).where(RefreshToken.token_hash == token_hash)
    )
    return result.scalar_one_or_none()


async def revoke_family(session: AsyncSession, family_id: uuid.UUID, now: datetime) -> None:
    """토큰 묶음 전체를 폐기한다.

    Args:
        session: DB 세션.
        family_id: 폐기할 묶음.
        now: 현재 시각.
    """
    await session.execute(
        update(RefreshToken)
        .where(RefreshToken.family_id == family_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=now)
    )
