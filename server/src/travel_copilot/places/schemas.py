"""장소 API 스키마와 Google 응답 검증 모델.

Google 응답도 외부 입력으로 다룬다 (features/itinerary.md 5.7). 형식이 맞지 않으면 버린다.
"""

from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field, StringConstraints

# place_id는 Google 요청 URL 경로에 들어간다. 경로를 바꿀 수 있는 문자(/ . ? % 등)를 막는다 (T32)
PLACE_ID_PATTERN = r"^[A-Za-z0-9_-]{1,255}$"
SESSION_TOKEN_PATTERN = r"^[A-Za-z0-9_-]{16,64}$"  # noqa: S105  # 비밀값이 아니라 형식 규칙

PlaceId = Annotated[str, StringConstraints(pattern=PLACE_ID_PATTERN)]
SessionToken = Annotated[str, StringConstraints(pattern=SESSION_TOKEN_PATTERN)]
Latitude = Annotated[float, Field(ge=-90, le=90)]
Longitude = Annotated[float, Field(ge=-180, le=180)]

ATTRIBUTION = "Google Maps"


class LatLng(BaseModel):
    """좌표."""

    lat: Latitude
    lng: Longitude


class Suggestion(BaseModel):
    """자동완성 결과 한 줄."""

    place_id: str
    name: str
    secondary: str | None


class AutocompleteResponse(BaseModel):
    """자동완성 응답."""

    suggestions: list[Suggestion]
    attribution: str = ATTRIBUTION


class PlaceRead(BaseModel):
    """장소 상세 응답. 장소 이름은 Pro 요금 필드라 담지 않는다 (5.1)."""

    place_id: str
    address: str | None
    location: LatLng
    maps_url: str
    attribution: str = ATTRIBUTION


# --- Google 응답 (필요한 필드만, 나머지는 무시) --------------------------------


class _GoogleModel(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)


class _GoogleText(_GoogleModel):
    text: Annotated[str, StringConstraints(min_length=1, max_length=300)]


class _GoogleStructuredFormat(_GoogleModel):
    main_text: _GoogleText = Field(alias="mainText")
    secondary_text: _GoogleText | None = Field(default=None, alias="secondaryText")


class GooglePlacePrediction(_GoogleModel):
    """자동완성의 장소 결과."""

    place_id: PlaceId = Field(alias="placeId")
    structured_format: _GoogleStructuredFormat = Field(alias="structuredFormat")


class GoogleLatLng(_GoogleModel):
    """Google 좌표 형식."""

    latitude: Latitude
    longitude: Longitude


class GooglePlace(_GoogleModel):
    """장소 상세 (필드 마스크로 요청한 필드만)."""

    id: PlaceId
    formatted_address: Annotated[str, StringConstraints(max_length=500)] | None = Field(
        default=None, alias="formattedAddress"
    )
    location: GoogleLatLng
