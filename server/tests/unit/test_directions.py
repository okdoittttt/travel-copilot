"""Routes 요청·응답 단위 테스트."""

from typing import Any

import pytest

from travel_copilot.directions.client import RouteResult, build_request, parse_route
from travel_copilot.itinerary.models import TravelMode


def test_drive_request_is_traffic_unaware_without_departure_time() -> None:
    body = build_request("a", "b", TravelMode.DRIVE)

    assert body["travelMode"] == "DRIVE"
    assert body["routingPreference"] == "TRAFFIC_UNAWARE"
    assert "departureTime" not in body
    assert body["origin"] == {"placeId": "a"}


@pytest.mark.parametrize(
    ("mode", "google"), [(TravelMode.TRANSIT, "TRANSIT"), (TravelMode.WALK, "WALK")]
)
def test_non_drive_request_has_no_routing_preference(mode: TravelMode, google: str) -> None:
    body = build_request("a", "b", mode)

    assert body["travelMode"] == google
    assert "routingPreference" not in body


@pytest.mark.parametrize(
    ("data", "expected"),
    [
        ({"routes": [{"duration": "1260s", "distanceMeters": 3900}]}, RouteResult(1260, 3900)),
        ({"routes": [{"duration": "59.5s", "distanceMeters": 10}]}, RouteResult(59, 10)),
        ({"routes": [{"duration": "0s"}]}, RouteResult(0, 0)),  # 거리 0은 필드가 빠진다
    ],
)
def test_parse_route(data: dict[str, Any], expected: RouteResult) -> None:
    assert parse_route(data) == expected


@pytest.mark.parametrize(
    "data",
    [
        {},  # 경로 없음
        {"routes": []},
        {"routes": [{"duration": "-5s", "distanceMeters": 1}]},
        {"routes": [{"duration": "abc", "distanceMeters": 1}]},
        {"routes": [{"duration": "999999999s", "distanceMeters": 1}]},
        {"routes": [{"duration": "10s", "distanceMeters": -1}]},
        {"routes": [{"duration": "10s", "distanceMeters": "100"}]},
        {"routes": [{"duration": "10s", "distanceMeters": True}]},
        ["not", "object"],
    ],
)
def test_parse_route_rejects_bad_data(data: object) -> None:
    assert parse_route(data) is None
