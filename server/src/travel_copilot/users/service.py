"""내 정보 변경."""

from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.users.models import User


async def update_display_name(session: AsyncSession, user: User, display_name: str) -> User:
    """표시 이름을 바꾸고 저장한다.

    Args:
        session: 요청 단위 DB 세션 (user를 읽어온 세션).
        user: 바꿀 사용자.
        display_name: 새 표시 이름 (스키마에서 길이·공백 검증 완료).

    Returns:
        저장된 사용자.
    """
    user.display_name = display_name
    await session.commit()
    await session.refresh(user)
    return user
