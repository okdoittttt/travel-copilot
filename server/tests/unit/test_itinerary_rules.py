"""일정·장소 규칙 단위 테스트."""

import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal
from typing import Any

import pytest
from pydantic import ValidationError

from travel_copilot.itinerary.models import ItineraryItem
from travel_copilot.itinerary.schemas import ItemCreate, ItemUpdate
from travel_copilot.itinerary.service import item_read
from travel_copilot.places.cache import LocationCache
from travel_copilot.places.router import maps_url
from travel_copilot.places.schemas import LatLng

BASE: dict[str, Any] = {"day": "2026-12-21", "title": "오르세"}


def test_item_create_accepts_full_input() -> None:
    item = ItemCreate(
        **BASE,
        memo="야간 개장\n목요일",
        place_id="ChIJ_abc-123",
        start_time="10:00",
        stay_minutes=180,
        travel_mode="transit",
    )

    assert item.memo == "야간 개장\n목요일"
    assert item.start_time is not None
    assert item.start_time.hour == 10


@pytest.mark.parametrize(
    "overrides",
    [
        {"title": ""},
        {"title": "가" * 101},
        {"title": "줄\n바꿈"},
        {"memo": "탭\t문자"},
        {"memo": "가" * 1001},
        {"start_time": "10:00:30"},
        {"stay_minutes": -1},
        {"stay_minutes": 1441},
        {"travel_mode": "fly"},
        {"place_id": "../places:autocomplete"},
        {"place_id": "abc/def"},
        {"place_id": "abc?x=1"},
        {"place_id": "a" * 256},
        {"location": {"lat": 1, "lng": 2}},  # 좌표는 받지 않는다
    ],
)
def test_item_create_rejects_invalid_input(overrides: dict[str, Any]) -> None:
    with pytest.raises(ValidationError):
        ItemCreate(**{**BASE, **overrides})


def test_item_update_allows_clearing_optional_fields() -> None:
    update = ItemUpdate(version=1, memo=None, place_id=None)

    assert update.changes() == {"memo": None, "place_id": None}


@pytest.mark.parametrize("field", ["title", "day"])
def test_item_update_rejects_null_required_field(field: str) -> None:
    with pytest.raises(ValidationError):
        ItemUpdate(version=1, **{field: None})


def test_item_update_requires_a_change() -> None:
    with pytest.raises(ValidationError):
        ItemUpdate(version=1)


def _item(fetched_at: datetime | None) -> ItineraryItem:
    return ItineraryItem(
        id=uuid.uuid4(),
        trip_id=uuid.uuid4(),
        day=date(2026, 12, 21),
        position=0,
        title="오르세",
        google_place_id="ChIJ_abc",
        lat=Decimal("48.860000") if fetched_at else None,
        lng=Decimal("2.326600") if fetched_at else None,
        location_fetched_at=fetched_at,
        version=1,
        updated_at=datetime.now(UTC),
    )


def test_item_read_shows_fresh_location() -> None:
    now = datetime.now(UTC)

    read = item_read(_item(now - timedelta(days=29)), now)

    assert read.location == LatLng(lat=48.86, lng=2.3266)


def test_item_read_hides_location_older_than_30_days() -> None:
    now = datetime.now(UTC)

    read = item_read(_item(now - timedelta(days=30)), now)

    assert read.location is None
    assert read.place_id == "ChIJ_abc"


def test_location_cache_expires(monkeypatch: pytest.MonkeyPatch) -> None:
    clock = [1000.0]
    monkeypatch.setattr("travel_copilot.places.cache.time.monotonic", lambda: clock[0])
    cache = LocationCache(ttl_seconds=600)
    user = uuid.uuid4()
    cache.put(user, "p1", LatLng(lat=1, lng=2))

    assert cache.get(user, "p1") == LatLng(lat=1, lng=2)
    assert cache.get(uuid.uuid4(), "p1") is None  # 다른 사용자 것은 안 보인다
    clock[0] += 600
    assert cache.get(user, "p1") is None


def test_location_cache_is_bounded() -> None:
    cache = LocationCache(max_entries=3)
    user = uuid.uuid4()
    for i in range(5):
        cache.put(user, f"p{i}", LatLng(lat=0, lng=0))

    assert cache.get(user, "p0") is None
    assert cache.get(user, "p4") is not None


def test_maps_url_uses_official_format() -> None:
    url = maps_url("ChIJ_abc", "1 Rue & Paris")

    assert url.startswith("https://www.google.com/maps/search/?api=1&")
    assert "query_place_id=ChIJ_abc" in url
    assert "query=1+Rue+%26+Paris" in url
