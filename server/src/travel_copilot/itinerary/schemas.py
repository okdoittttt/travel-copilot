"""일정 항목 API 스키마."""

import uuid
from datetime import date, datetime, time
from typing import Annotated, Any, Self

from pydantic import BaseModel, Field, field_serializer, model_validator

from travel_copilot.core.schemas import RequestModel
from travel_copilot.itinerary.models import TravelMode
from travel_copilot.places.schemas import LatLng, PlaceId

MAX_ITEMS_PER_DAY = 50

ItemTitle = Annotated[str, Field(min_length=1, max_length=100, pattern=r"^[^\x00-\x1f\x7f]+$")]
# 메모는 줄바꿈(\n)만 허용하고 나머지 제어 문자는 거절한다
ItemMemo = Annotated[str, Field(max_length=1000, pattern=r"^[^\x00-\x09\x0b-\x1f\x7f]*$")]
StayMinutes = Annotated[int, Field(ge=0, le=1440)]


def _check_hh_mm(value: time | None) -> None:
    if value is not None and (value.second or value.microsecond or value.tzinfo):
        msg = "시각은 HH:MM 형식이어야 합니다"
        raise ValueError(msg)


class ItemCreate(RequestModel):
    """일정 항목 추가. 항상 그날 맨 뒤에 붙는다. 좌표는 받지 않는다 (서버가 Google에서 받음)."""

    day: date
    title: ItemTitle
    memo: ItemMemo | None = None
    place_id: PlaceId | None = None
    start_time: time | None = None
    stay_minutes: StayMinutes | None = None
    travel_mode: TravelMode | None = None

    @model_validator(mode="after")
    def _check_time(self) -> Self:
        _check_hh_mm(self.start_time)
        return self


# null을 보내면 지우는 필드 (features/itinerary.md 6.1)
CLEARABLE_FIELDS = frozenset({"memo", "place_id", "start_time", "stay_minutes", "travel_mode"})


class ItemUpdate(RequestModel):
    """일정 항목 수정. 바꿀 필드만 보낸다."""

    version: int = Field(ge=1)
    day: date | None = None
    title: ItemTitle | None = None
    memo: ItemMemo | None = None
    place_id: PlaceId | None = None
    start_time: time | None = None
    stay_minutes: StayMinutes | None = None
    travel_mode: TravelMode | None = None

    @model_validator(mode="after")
    def _check_fields(self) -> Self:
        changed = self.model_fields_set - {"version"}
        if not changed:
            msg = "바꿀 항목이 없습니다"
            raise ValueError(msg)
        for name in ("day", "title"):
            if name in changed and getattr(self, name) is None:
                msg = f"{name}은(는) 비울 수 없습니다"
                raise ValueError(msg)
        _check_hh_mm(self.start_time)
        return self

    def changes(self) -> dict[str, Any]:
        """보낸 필드(version 제외)와 값. null은 지우기다.

        Returns:
            필드 이름과 새 값.
        """
        return {name: getattr(self, name) for name in self.model_fields_set - {"version"}}


class OrderEntry(RequestModel):
    """순서 변경 목록의 한 줄."""

    id: uuid.UUID
    version: int = Field(ge=1)


class ReorderRequest(RequestModel):
    """하루 순서 변경. 그날의 모든 항목이 정확히 들어 있어야 한다."""

    items: list[OrderEntry] = Field(max_length=MAX_ITEMS_PER_DAY)


class ItemRead(BaseModel):
    """일정 항목 응답. 30일 지난 좌표는 `location`이 null."""

    id: uuid.UUID
    day: date
    position: int
    title: str
    memo: str | None
    place_id: str | None
    location: LatLng | None
    start_time: time | None
    stay_minutes: int | None
    travel_mode: TravelMode | None
    version: int
    updated_at: datetime

    @field_serializer("start_time")
    def _serialize_time(self, value: time | None) -> str | None:
        return value.strftime("%H:%M") if value else None


class DayItems(BaseModel):
    """하루 일정."""

    date: date
    items: list[ItemRead]
