"""Google Places API (New) 클라이언트 (features/itinerary.md 5.1·5.6·5.7)."""

import logging
import re
from dataclasses import dataclass

import httpx
from pydantic import ValidationError

from travel_copilot.core.errors import UpstreamError
from travel_copilot.places.schemas import (
    PLACE_ID_PATTERN,
    GooglePlace,
    GooglePlacePrediction,
    LatLng,
    Suggestion,
)

logger = logging.getLogger(__name__)

PLACES_BASE_URL = "https://places.googleapis.com/v1"
AUTOCOMPLETE_URL = f"{PLACES_BASE_URL}/places:autocomplete"

# 필드 마스크는 상수로 고정한다. 요청 값으로 바꿀 수 없다.
# displayName·googleMapsUri는 Pro 요금 필드라 넣지 않는다 (5.1)
AUTOCOMPLETE_FIELD_MASK = (
    "suggestions.placePrediction.placeId,suggestions.placePrediction.structuredFormat"
)
DETAILS_FIELD_MASK = "id,formattedAddress,location"

LANGUAGE_CODE = "ko"
BIAS_RADIUS_METERS = 50_000.0
MAX_SUGGESTIONS = 10

_PLACE_ID = re.compile(PLACE_ID_PATTERN)


@dataclass(frozen=True, slots=True)
class PlaceDetails:
    """검증을 통과한 장소 상세."""

    place_id: str
    address: str | None
    location: LatLng


class GooglePlacesClient:
    """Places API (New)를 부른다. API 키는 헤더로만 보낸다 (URL에 남지 않게, T20)."""

    def __init__(self, http: httpx.AsyncClient, api_key: str) -> None:
        """클라이언트를 만든다.

        Args:
            http: 타임아웃이 설정된 공용 HTTP 클라이언트.
            api_key: 서버용 Places API 키.
        """
        self._http = http
        self._api_key = api_key

    def _headers(self, field_mask: str) -> dict[str, str]:
        return {"X-Goog-Api-Key": self._api_key, "X-Goog-FieldMask": field_mask}

    async def autocomplete(
        self, query: str, session_token: str | None, bias: LatLng | None
    ) -> list[Suggestion]:
        """자동완성 결과를 받는다.

        Args:
            query: 검색어 (검증 완료).
            session_token: 과금 세션 토큰. 장소 상세까지 같은 값을 쓴다.
            bias: 결과를 치우칠 중심 좌표.

        Returns:
            형식이 맞는 장소 결과만. 형식이 이상한 항목은 버린다.

        Raises:
            UpstreamError: Google 호출이 실패했을 때.
        """
        body: dict[str, object] = {"input": query, "languageCode": LANGUAGE_CODE}
        if session_token:
            body["sessionToken"] = session_token
        if bias:
            body["locationBias"] = {
                "circle": {
                    "center": {"latitude": bias.lat, "longitude": bias.lng},
                    "radius": BIAS_RADIUS_METERS,
                }
            }
        data = await self._request("POST", AUTOCOMPLETE_URL, AUTOCOMPLETE_FIELD_MASK, json=body)
        raw = data.get("suggestions", []) if isinstance(data, dict) else []
        suggestions: list[Suggestion] = []
        for item in raw if isinstance(raw, list) else []:
            prediction = item.get("placePrediction") if isinstance(item, dict) else None
            if prediction is None:
                continue  # 장소가 아닌 검색어 제안은 쓰지 않는다
            try:
                parsed = GooglePlacePrediction.model_validate(prediction)
            except ValidationError:
                logger.warning("Google 자동완성 결과 형식 오류, 버림")
                continue
            secondary = parsed.structured_format.secondary_text
            suggestions.append(
                Suggestion(
                    place_id=parsed.place_id,
                    name=parsed.structured_format.main_text.text,
                    secondary=secondary.text if secondary else None,
                )
            )
        return suggestions[:MAX_SUGGESTIONS]

    async def details(self, place_id: str, session_token: str | None) -> PlaceDetails:
        """장소 상세(주소·좌표)를 받는다. Essentials 등급 필드만 요청한다.

        Args:
            place_id: Google 장소 ID (형식 검증 완료).
            session_token: 자동완성 세션을 끝낼 때의 토큰. 없으면 단독 호출.

        Returns:
            검증된 장소 상세.

        Raises:
            UpstreamError: Google 호출이 실패했거나 응답 형식이 맞지 않을 때.
        """
        # 스키마에서 이미 검증하지만, URL 경로에 넣는 값이라 한 번 더 막는다 (T32)
        if not _PLACE_ID.fullmatch(place_id):
            raise UpstreamError
        params = {"languageCode": LANGUAGE_CODE}
        if session_token:
            params["sessionToken"] = session_token
        data = await self._request(
            "GET", f"{PLACES_BASE_URL}/places/{place_id}", DETAILS_FIELD_MASK, params=params
        )
        try:
            place = GooglePlace.model_validate(data)
        except ValidationError as exc:
            logger.warning("Google 장소 상세 형식 오류")
            raise UpstreamError from exc
        return PlaceDetails(
            place_id=place.id,
            address=place.formatted_address,
            location=LatLng(lat=place.location.latitude, lng=place.location.longitude),
        )

    async def _request(
        self,
        method: str,
        url: str,
        field_mask: str,
        **kwargs: object,
    ) -> object:
        try:
            response = await self._http.request(
                method,
                url,
                headers=self._headers(field_mask),
                **kwargs,  # type: ignore[arg-type]
            )
        except httpx.HTTPError as exc:
            logger.warning("Google Places 연결 실패: %s", type(exc).__name__)
            raise UpstreamError from exc
        if response.status_code != 200:
            # Google 에러 본문은 응답·로그에 넣지 않는다 (키·요청 내용이 섞일 수 있음)
            logger.warning("Google Places 오류 응답: status=%s", response.status_code)
            raise UpstreamError
        try:
            return response.json()
        except ValueError as exc:
            raise UpstreamError from exc
