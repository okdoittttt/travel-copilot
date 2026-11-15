"""장소 API (features/itinerary.md 6.2). 여행과 무관해서 로그인만 확인한다."""

from typing import Annotated
from urllib.parse import urlencode

from fastapi import APIRouter, Depends, Path, Query

from travel_copilot.auth.dependencies import CurrentUser
from travel_copilot.places.dependencies import (
    Locations,
    PlacesClient,
    autocomplete_rate_limit,
    details_rate_limit,
)
from travel_copilot.places.schemas import (
    PLACE_ID_PATTERN,
    SESSION_TOKEN_PATTERN,
    AutocompleteResponse,
    Latitude,
    LatLng,
    Longitude,
    PlaceRead,
)

router = APIRouter(prefix="/places", tags=["places"])


def maps_url(place_id: str, address: str | None) -> str:
    """Google 공식 Maps URLs 형식의 "Google 지도에서 열기" 링크.

    `googleMapsUri` 필드는 Pro 요금이라, place_id로 직접 만든다 (5.1).

    Args:
        place_id: Google 장소 ID.
        address: 검색어로 쓸 주소. 없으면 place_id.

    Returns:
        https 링크.
    """
    query = urlencode({"api": "1", "query": address or place_id, "query_place_id": place_id})
    return f"https://www.google.com/maps/search/?{query}"


@router.get("/autocomplete", dependencies=[Depends(autocomplete_rate_limit)])
async def autocomplete(
    client: PlacesClient,
    q: Annotated[str, Query(min_length=1, max_length=100)],
    session_token: Annotated[str | None, Query(pattern=SESSION_TOKEN_PATTERN)] = None,
    lat: Annotated[Latitude | None, Query()] = None,
    lng: Annotated[Longitude | None, Query()] = None,
) -> AutocompleteResponse:
    """장소 자동완성. 결과는 화면 표시용이고 저장하지 않는다."""
    query = q.strip()
    bias = LatLng(lat=lat, lng=lng) if lat is not None and lng is not None else None
    if not query:
        return AutocompleteResponse(suggestions=[])
    return AutocompleteResponse(suggestions=await client.autocomplete(query, session_token, bias))


@router.get("/{place_id}", dependencies=[Depends(details_rate_limit)])
async def place_details(
    user: CurrentUser,
    client: PlacesClient,
    locations: Locations,
    place_id: Annotated[str, Path(pattern=PLACE_ID_PATTERN)],
    session_token: Annotated[str | None, Query(pattern=SESSION_TOKEN_PATTERN)] = None,
) -> PlaceRead:
    """장소 상세(주소·좌표). 받은 좌표는 일정 저장에 쓰려고 10분 기억한다."""
    details = await client.details(place_id, session_token)
    locations.put(user.id, details.place_id, details.location)
    return PlaceRead(
        place_id=details.place_id,
        address=details.address,
        location=details.location,
        maps_url=maps_url(details.place_id, details.address),
    )
