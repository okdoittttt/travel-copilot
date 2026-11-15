"""Google Routes API 클라이언트 (features/routes-map.md 5.1).

교통 미반영(Essentials) 요청만 보낸다. 결과는 저장하지 않는다 (5.2, Google 약관).
"""

import logging
import re
from dataclasses import dataclass

import httpx

from travel_copilot.core.errors import UpstreamError
from travel_copilot.itinerary.models import TravelMode
from travel_copilot.places.schemas import PLACE_ID_PATTERN

logger = logging.getLogger(__name__)

COMPUTE_ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes"
# 필드 마스크는 상수로 고정한다. 요금 등급은 기능으로 정해지지만 필요한 값만 받는다
FIELD_MASK = "routes.duration,routes.distanceMeters"
LANGUAGE_CODE = "ko"

_GOOGLE_MODE = {
    TravelMode.DRIVE: "DRIVE",
    TravelMode.TRANSIT: "TRANSIT",
    TravelMode.WALK: "WALK",
}
_DURATION = re.compile(r"^(\d{1,7})(?:\.\d+)?s$")
_PLACE_ID = re.compile(PLACE_ID_PATTERN)

# Google 응답도 외부 입력: 말이 안 되는 값은 버린다
MAX_DURATION_SECONDS = 7 * 24 * 3600
MAX_DISTANCE_METERS = 20_000_000


@dataclass(frozen=True, slots=True)
class RouteResult:
    """검증을 통과한 이동시간·거리."""

    duration_seconds: int
    distance_meters: int


def build_request(
    origin_place_id: str, destination_place_id: str, mode: TravelMode
) -> dict[str, object]:
    """ComputeRoutes 요청 본문을 만든다.

    차량은 교통 미반영(`TRAFFIC_UNAWARE`)으로 고정하고 출발 시각을 보내지 않는다.
    실시간 교통은 Pro 등급이다 (5.1).

    Args:
        origin_place_id: 출발 장소 ID (형식 검증 완료).
        destination_place_id: 도착 장소 ID (형식 검증 완료).
        mode: 이동수단.

    Returns:
        JSON 본문.
    """
    body: dict[str, object] = {
        "origin": {"placeId": origin_place_id},
        "destination": {"placeId": destination_place_id},
        "travelMode": _GOOGLE_MODE[mode],
        "languageCode": LANGUAGE_CODE,
    }
    if mode is TravelMode.DRIVE:
        # routingPreference는 차량에만 쓸 수 있다
        body["routingPreference"] = "TRAFFIC_UNAWARE"
    return body


def parse_route(data: object) -> RouteResult | None:
    """ComputeRoutes 응답에서 첫 경로의 이동시간·거리를 꺼낸다.

    Args:
        data: Google 응답 JSON.

    Returns:
        경로 결과. 경로가 없거나 형식이 맞지 않으면 None.
    """
    if not isinstance(data, dict):
        return None
    routes = data.get("routes")
    if not isinstance(routes, list) or not routes or not isinstance(routes[0], dict):
        return None
    route = routes[0]
    match = _DURATION.fullmatch(str(route.get("duration", "")))
    # 거리가 0이면 Google이 필드를 빼고 보낸다
    distance = route.get("distanceMeters", 0)
    if match is None or isinstance(distance, bool) or not isinstance(distance, int):
        return None
    duration = int(match.group(1))
    if not 0 <= duration <= MAX_DURATION_SECONDS or not 0 <= distance <= MAX_DISTANCE_METERS:
        return None
    return RouteResult(duration_seconds=duration, distance_meters=distance)


class GoogleRoutesClient:
    """Routes API를 부른다. 키는 헤더로만 보낸다 (T20)."""

    def __init__(self, http: httpx.AsyncClient, api_key: str) -> None:
        """클라이언트를 만든다.

        Args:
            http: 타임아웃이 설정된 공용 HTTP 클라이언트.
            api_key: 서버용 키 (Places API (New) + Routes API 허용).
        """
        self._http = http
        self._api_key = api_key

    async def compute(
        self, origin_place_id: str, destination_place_id: str, mode: TravelMode
    ) -> RouteResult | None:
        """두 장소 사이 경로 하나를 계산한다.

        Args:
            origin_place_id: 출발 장소 ID.
            destination_place_id: 도착 장소 ID.
            mode: 이동수단.

        Returns:
            경로 결과. Google이 경로를 찾지 못하면 None.

        Raises:
            UpstreamError: 호출 실패, 오류 응답, 잘못된 장소 ID.
        """
        if not (_PLACE_ID.fullmatch(origin_place_id) and _PLACE_ID.fullmatch(destination_place_id)):
            raise UpstreamError
        try:
            response = await self._http.post(
                COMPUTE_ROUTES_URL,
                json=build_request(origin_place_id, destination_place_id, mode),
                headers={"X-Goog-Api-Key": self._api_key, "X-Goog-FieldMask": FIELD_MASK},
            )
        except httpx.HTTPError as exc:
            logger.warning("Google Routes 연결 실패: %s", type(exc).__name__)
            raise UpstreamError from exc
        if response.status_code != 200:
            # 에러 본문은 남기지 않는다 (키·요청 내용이 섞일 수 있음)
            logger.warning("Google Routes 오류 응답: status=%s", response.status_code)
            raise UpstreamError
        try:
            data = response.json()
        except ValueError as exc:
            raise UpstreamError from exc
        result = parse_route(data)
        if result is None and isinstance(data, dict) and data.get("routes"):
            logger.warning("Google Routes 응답 형식 오류")
        return result
