"""장소 API 의존성."""

from typing import Annotated

from fastapi import Depends, Request

from travel_copilot.auth.dependencies import CurrentUser, get_settings
from travel_copilot.core.config import Settings
from travel_copilot.core.rate_limit import enforce
from travel_copilot.places.cache import LocationCache
from travel_copilot.places.client import GooglePlacesClient
from travel_copilot.places.errors import PlacesUnavailable

DAY_SECONDS = 86_400


def get_places_client(request: Request) -> GooglePlacesClient:
    """Places 클라이언트를 꺼낸다.

    Args:
        request: 현재 요청.

    Returns:
        앱 시작 시 만든 클라이언트.

    Raises:
        PlacesUnavailable: 서버에 Places 키가 없을 때.
    """
    client: GooglePlacesClient | None = request.app.state.places_client
    if client is None:
        raise PlacesUnavailable
    return client


def get_location_cache(request: Request) -> LocationCache:
    """좌표 캐시를 꺼낸다.

    Args:
        request: 현재 요청.

    Returns:
        앱 전체가 공유하는 캐시.
    """
    cache: LocationCache = request.app.state.location_cache
    return cache


async def autocomplete_rate_limit(
    request: Request, user: CurrentUser, settings: Annotated[Settings, Depends(get_settings)]
) -> None:
    """자동완성 사용자별 제한: 분당 + 하루 (T23)."""
    limiter = request.app.state.rate_limiter
    enforce(limiter, f"places-ac-min:{user.id}", settings.places_autocomplete_per_minute, 60)
    enforce(limiter, f"places-ac-day:{user.id}", settings.places_autocomplete_per_day, DAY_SECONDS)


async def details_rate_limit(
    request: Request, user: CurrentUser, settings: Annotated[Settings, Depends(get_settings)]
) -> None:
    """장소 상세 사용자별 제한: 하루 (T23)."""
    limiter = request.app.state.rate_limiter
    enforce(limiter, f"places-detail-day:{user.id}", settings.places_details_per_day, DAY_SECONDS)


PlacesClient = Annotated[GooglePlacesClient, Depends(get_places_client)]
Locations = Annotated[LocationCache, Depends(get_location_cache)]
