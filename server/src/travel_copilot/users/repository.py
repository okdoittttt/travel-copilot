"""사용자 DB 접근."""

import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.users.models import User


async def get_by_id(session: AsyncSession, user_id: uuid.UUID) -> User | None:
    """ID로 사용자를 찾는다.

    Args:
        session: DB 세션.
        user_id: 찾을 사용자 ID.

    Returns:
        사용자. 없으면 None.
    """
    return await session.get(User, user_id)


async def create(session: AsyncSession, display_name: str, email: str | None) -> User:
    """사용자를 만든다. 커밋은 호출하는 쪽이 한다.

    Args:
        session: DB 세션.
        display_name: 표시 이름.
        email: 표시·연락용 이메일. 로그인 식별에는 쓰지 않는다.

    Returns:
        DB에 반영(flush)된 사용자.
    """
    user = User(display_name=display_name, email=email)
    session.add(user)
    await session.flush()
    return user
