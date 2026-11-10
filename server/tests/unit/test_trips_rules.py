"""여행 규칙 단위 테스트: 역할 서열, 입력 검증, 목록 커서."""

import base64
import uuid
from datetime import date
from typing import Any

import pytest
from pydantic import ValidationError

from tests.conftest import TRIP_BODY
from travel_copilot.trips.errors import InvalidCursor
from travel_copilot.trips.models import TripRole
from travel_copilot.trips.schemas import MemberRoleUpdate, TripCreate, TripUpdate, period_is_valid
from travel_copilot.trips.service import decode_cursor, encode_cursor


@pytest.mark.parametrize(
    ("role", "minimum", "expected"),
    [
        (TripRole.OWNER, TripRole.OWNER, True),
        (TripRole.OWNER, TripRole.VIEWER, True),
        (TripRole.EDITOR, TripRole.EDITOR, True),
        (TripRole.EDITOR, TripRole.OWNER, False),
        (TripRole.VIEWER, TripRole.VIEWER, True),
        (TripRole.VIEWER, TripRole.EDITOR, False),
    ],
)
def test_role_at_least(role: TripRole, minimum: TripRole, expected: bool) -> None:
    assert role.at_least(minimum) is expected


@pytest.mark.parametrize(
    ("start", "end", "expected"),
    [
        (date(2026, 1, 1), date(2026, 1, 1), True),  # 당일치기
        (date(2026, 1, 1), date(2026, 3, 1), True),  # 양 끝 포함 60일
        (date(2026, 1, 1), date(2026, 3, 2), False),  # 61일
        (date(2026, 1, 2), date(2026, 1, 1), False),  # 순서 반대
    ],
)
def test_period_rule(start: date, end: date, expected: bool) -> None:
    assert period_is_valid(start, end) is expected


def test_trip_create_strips_whitespace() -> None:
    trip = TripCreate(**{**TRIP_BODY, "title": "  파리  "})

    assert trip.title == "파리"


@pytest.mark.parametrize(
    "overrides",
    [
        {"title": ""},
        {"title": "   "},
        {"title": "가" * 101},
        {"title": "줄\n바꿈"},
        {"destination": "탭\t문자"},
        {"timezone": "Mars/Olympus"},
        {"timezone": "KST"},
        {"start_date": "2026-12-28"},  # 종료일보다 늦음
        {"end_date": "2027-03-01"},  # 60일 초과
    ],
)
def test_trip_create_rejects_invalid_input(overrides: dict[str, Any]) -> None:
    with pytest.raises(ValidationError):
        TripCreate(**{**TRIP_BODY, **overrides})


def test_trip_update_requires_a_change() -> None:
    with pytest.raises(ValidationError):
        TripUpdate(version=1)


def test_trip_update_rejects_null() -> None:
    with pytest.raises(ValidationError):
        TripUpdate(version=1, title=None)


def test_trip_update_changes_excludes_version() -> None:
    update = TripUpdate(version=3, title="새 제목")

    assert update.changes() == {"title": "새 제목"}


def test_member_role_update_rejects_owner() -> None:
    with pytest.raises(ValidationError):
        MemberRoleUpdate(role=TripRole.OWNER)


def test_cursor_round_trip() -> None:
    trip_id = uuid.uuid4()

    assert decode_cursor(encode_cursor(date(2026, 12, 20), trip_id)) == (
        date(2026, 12, 20),
        trip_id,
    )


@pytest.mark.parametrize(
    "cursor",
    [
        "not-base64!!",
        base64.urlsafe_b64encode(b"not json").decode(),
        base64.urlsafe_b64encode(b'{"d":"2026-12-20"}').decode(),
        base64.urlsafe_b64encode(b'{"d":"yesterday","i":"x"}').decode(),
        base64.urlsafe_b64encode(b"[1,2]").decode(),
    ],
)
def test_tampered_cursor_is_rejected(cursor: str) -> None:
    with pytest.raises(InvalidCursor):
        decode_cursor(cursor)
