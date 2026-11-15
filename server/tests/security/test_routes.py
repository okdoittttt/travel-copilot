"""T06·T20·T23: 이동시간 계산 (features/routes-map.md 8절)."""

import asyncio
import json
import logging
from collections.abc import AsyncIterator

import httpx
import pytest
import respx
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import (
    EIFFEL_ID,
    LOUVRE_ID,
    ORSAY_ID,
    PLACES_KEY,
    SeededUser,
    add_item,
    client_for,
    create_trip,
    create_user,
    make_settings,
)
from travel_copilot.directions.client import FIELD_MASK
from travel_copilot.main import create_app

DAY = "2026-12-21"


async def _trip_with_places(
    client: AsyncClient, owner: SeededUser, count: int, mode: str = "transit"
) -> str:
    trip = await create_trip(client, owner)
    ids = [ORSAY_ID, LOUVRE_ID, EIFFEL_ID]
    for i in range(count):
        await add_item(
            client, owner, trip["id"], title=f"장소 {i}", place_id=ids[i % 3], travel_mode=mode
        )
    return str(trip["id"])


async def test_non_member_day_view_never_calls_google(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    owner = await create_user(db)
    stranger = await create_user(db)
    trip_id = await _trip_with_places(client, owner, 3)
    before = google_routes["routes"].call_count

    response = await client.get(f"/api/v1/trips/{trip_id}/days/{DAY}", headers=stranger.headers)

    assert response.status_code == 404
    assert google_routes["routes"].call_count == before


async def test_routes_request_is_essentials_only(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip_id = await _trip_with_places(client, owner, 2, mode="drive")

    await client.get(f"/api/v1/trips/{trip_id}/days/{DAY}", headers=owner.headers)

    request = google_routes["routes"].calls.last.request
    assert (
        request.headers["X-Goog-FieldMask"] == FIELD_MASK == "routes.duration,routes.distanceMeters"
    )
    body = json.loads(request.content)
    assert body["routingPreference"] == "TRAFFIC_UNAWARE"  # TRAFFIC_AWARE는 Pro
    for pro_feature in (
        "departureTime",
        "intermediates",
        "optimizeWaypointOrder",
        "extraComputations",
    ):
        assert pro_feature not in body


async def test_routes_key_not_exposed(
    client: AsyncClient,
    db: AsyncSession,
    google_routes: respx.MockRouter,
    caplog: pytest.LogCaptureFixture,
) -> None:
    owner = await create_user(db)
    trip_id = await _trip_with_places(client, owner, 2)
    google_routes["routes"].respond(status_code=403, text=f"bad key {PLACES_KEY}")
    caplog.set_level(logging.DEBUG)

    response = await client.get(f"/api/v1/trips/{trip_id}/days/{DAY}", headers=owner.headers)

    request = google_routes["routes"].calls.last.request
    assert request.headers["X-Goog-Api-Key"] == PLACES_KEY
    assert PLACES_KEY not in str(request.url)
    assert PLACES_KEY not in response.text
    assert PLACES_KEY not in caplog.text


async def test_routes_calls_bounded(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip_id = await _trip_with_places(client, owner, 12)
    in_flight = 0
    peak = 0

    async def slow(request: httpx.Request) -> httpx.Response:
        nonlocal in_flight, peak
        in_flight += 1
        peak = max(peak, in_flight)
        await asyncio.sleep(0.02)
        in_flight -= 1
        return httpx.Response(200, json={"routes": [{"duration": "60s", "distanceMeters": 100}]})

    google_routes["routes"].side_effect = slow
    before = google_routes["routes"].call_count

    response = await client.get(f"/api/v1/trips/{trip_id}/days/{DAY}", headers=owner.headers)

    assert response.status_code == 200
    assert google_routes["routes"].call_count - before == 11  # 12개 항목 → 11구간
    # 명세의 값(5)과 비교한다. 코드 상수와 비교하면 상수를 바꿔도 테스트가 통과해 버린다
    assert 1 < peak <= 5


async def test_legs_are_not_cached(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip_id = await _trip_with_places(client, owner, 2)
    url = f"/api/v1/trips/{trip_id}/days/{DAY}"

    await client.get(url, headers=owner.headers)
    await client.get(url, headers=owner.headers)

    assert google_routes["routes"].call_count == 2
    tables = await db.scalar(
        text("SELECT count(*) FROM information_schema.columns WHERE column_name LIKE '%duration%'")
    )
    assert tables == 0  # 이동시간을 저장하는 컬럼이 없다


@pytest.mark.parametrize(
    "response",
    [
        httpx.Response(200, json={"routes": [{"duration": "-1s", "distanceMeters": 1}]}),
        httpx.Response(200, json={}),
        httpx.Response(500, json={"error": "internal"}),
    ],
)
async def test_invalid_route_response_is_unavailable(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter, response: httpx.Response
) -> None:
    owner = await create_user(db)
    trip_id = await _trip_with_places(client, owner, 2)
    google_routes["routes"].mock(return_value=response)

    body = (await client.get(f"/api/v1/trips/{trip_id}/days/{DAY}", headers=owner.headers)).json()

    assert body["legs"][0]["status"] == "unavailable"
    assert body["legs"][0]["duration_seconds"] is None


async def test_partial_route_failure(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip_id = await _trip_with_places(client, owner, 3)
    google_routes["routes"].side_effect = [
        httpx.ConnectTimeout("timeout"),
        httpx.Response(200, json={"routes": [{"duration": "60s", "distanceMeters": 100}]}),
    ]

    response = await client.get(f"/api/v1/trips/{trip_id}/days/{DAY}", headers=owner.headers)

    assert response.status_code == 200
    statuses = sorted(leg["status"] for leg in response.json()["legs"])
    assert statuses == ["ok", "unavailable"]


@pytest.fixture
async def limited_client(
    db: AsyncSession, migrated_database_url: str
) -> AsyncIterator[AsyncClient]:
    app = create_app(make_settings(database_url=migrated_database_url, day_view_per_hour=2))
    async with client_for(app) as c:
        yield c


async def test_day_view_rate_limit(
    limited_client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip_id = await _trip_with_places(limited_client, owner, 2)
    url = f"/api/v1/trips/{trip_id}/days/{DAY}"

    statuses = [
        (await limited_client.get(url, headers=owner.headers)).status_code for _ in range(3)
    ]

    assert statuses == [200, 200, 429]
    assert google_routes["routes"].call_count == 2  # 제한에 걸린 요청은 Google까지 가지 않는다
