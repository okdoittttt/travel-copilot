"""초대 API 의존성."""

from typing import Annotated

from fastapi import Depends, Request

from travel_copilot.auth.dependencies import CurrentUser, get_settings
from travel_copilot.core.config import Settings
from travel_copilot.core.rate_limit import enforce


async def redeem_rate_limit(
    request: Request, user: CurrentUser, settings: Annotated[Settings, Depends(get_settings)]
) -> None:
    """미리보기·참여 합산 사용자별 분당 제한 (06-api 5절, T10)."""
    enforce(
        request.app.state.rate_limiter,
        f"invite-redeem:{user.id}",
        settings.invite_redeem_per_minute,
        60,
    )
