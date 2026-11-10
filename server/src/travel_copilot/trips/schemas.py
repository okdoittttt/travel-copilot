"""여행 API 요청·응답 스키마."""

import uuid
import zoneinfo
from datetime import date, datetime
from functools import cache
from typing import Annotated, Any, Literal, Self

from pydantic import AfterValidator, BaseModel, Field, model_validator

from travel_copilot.core.schemas import RequestModel
from travel_copilot.trips.models import TripRole

MAX_TRIP_DAYS = 60
LIST_LIMIT_DEFAULT = 20
LIST_LIMIT_MAX = 50

# 줄바꿈·탭 같은 제어 문자는 받지 않는다 (화면 깨짐, 로그 위조 방지)
_NO_CONTROL_CHARS = r"^[^\x00-\x1f\x7f]+$"

TripText = Annotated[str, Field(min_length=1, max_length=100, pattern=_NO_CONTROL_CHARS)]


@cache
def _known_timezones() -> frozenset[str]:
    return frozenset(zoneinfo.available_timezones())


def _check_timezone(value: str) -> str:
    if value not in _known_timezones():
        msg = "알 수 없는 시간대입니다"
        raise ValueError(msg)
    return value


TimezoneName = Annotated[str, Field(min_length=1, max_length=64), AfterValidator(_check_timezone)]


def period_is_valid(start: date, end: date) -> bool:
    """여행 기간 규칙을 확인한다.

    Args:
        start: 시작일 (현지 날짜).
        end: 종료일 (현지 날짜).

    Returns:
        시작일이 종료일보다 늦지 않고, 양 끝 포함 60일 이하면 True.
    """
    return start <= end and (end - start).days + 1 <= MAX_TRIP_DAYS


class TripCreate(RequestModel):
    """여행 만들기 요청. 만든 사람이 owner가 되며, 역할은 요청으로 받지 않는다."""

    title: TripText
    destination: TripText
    start_date: date
    end_date: date
    timezone: TimezoneName

    @model_validator(mode="after")
    def _check_period(self) -> Self:
        if not period_is_valid(self.start_date, self.end_date):
            msg = f"종료일은 시작일 이후, 최대 {MAX_TRIP_DAYS}일이어야 합니다"
            raise ValueError(msg)
        return self


class TripUpdate(RequestModel):
    """여행 수정 요청. 바꿀 필드만 보낸다. 기간 규칙은 기존 값과 합쳐서 서비스가 확인한다."""

    version: int = Field(ge=1)
    title: TripText | None = None
    destination: TripText | None = None
    start_date: date | None = None
    end_date: date | None = None
    timezone: TimezoneName | None = None

    @model_validator(mode="after")
    def _check_fields(self) -> Self:
        changed = self.model_fields_set - {"version"}
        if not changed:
            msg = "바꿀 항목이 없습니다"
            raise ValueError(msg)
        # null은 "값 지우기"로 오해할 수 있어서 받지 않는다. 안 바꿀 필드는 빼고 보낸다
        if any(getattr(self, name) is None for name in changed):
            msg = "null은 보낼 수 없습니다. 바꾸지 않을 항목은 빼고 보내주세요"
            raise ValueError(msg)
        return self

    def changes(self) -> dict[str, Any]:
        """보낸 필드 중 version을 뺀 값.

        Returns:
            컬럼 이름과 새 값.
        """
        return {name: getattr(self, name) for name in self.model_fields_set - {"version"}}


class MemberRoleUpdate(RequestModel):
    """역할 변경 요청. owner는 소유권 넘기기로만 바꾼다."""

    role: Literal[TripRole.EDITOR, TripRole.VIEWER]


class OwnershipTransfer(RequestModel):
    """소유권 넘기기 요청."""

    user_id: uuid.UUID


class TripRead(BaseModel):
    """여행 정보와 요청자 기준 정보(내 역할, 멤버 수)."""

    id: uuid.UUID
    title: str
    destination: str
    start_date: date
    end_date: date
    timezone: str
    version: int
    my_role: TripRole
    member_count: int
    updated_at: datetime


class TripList(BaseModel):
    """여행 목록 한 페이지."""

    items: list[TripRead]
    next_cursor: str | None


class MemberRead(BaseModel):
    """여행 멤버. 다른 멤버의 이메일 등 연락처는 담지 않는다."""

    user_id: uuid.UUID
    display_name: str
    role: TripRole
    joined_at: datetime


class TripSnapshot(BaseModel):
    """여행 스냅샷. F3에서 일정, F7에서 바우처가 추가된다."""

    trip: TripRead
    members: list[MemberRead]
