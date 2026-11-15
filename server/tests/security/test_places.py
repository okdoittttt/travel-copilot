"""T20·T23·T32: Google Places 대리 호출 (features/itinerary.md 5.5~5.7, 8절)."""

import logging
from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta

import pytest
import respx
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import (
    ORSAY_ID,
    PLACES_KEY,
    add_item,
    client_for,
    create_trip,
    create_user,
    make_settings,
    place_details_body,
)
from travel_copilot.jobs.expire_locations import expire_locations
from travel_copilot.main import create_app
from travel_copilot.places.client import DETAILS_FIELD_MASK, PLACES_BASE_URL

PLACES = "/api/v1/places"


# --- T20: API 키 ---------------------------------------------------------------


async def test_places_key_sent_in_header_not_url(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    user = await create_user(db)

    await client.get(f"{PLACES}/autocomplete", params={"q": "파리"}, headers=user.headers)
    await client.get(f"{PLACES}/{ORSAY_ID}", headers=user.headers)

    for route in ("autocomplete", "details"):
        request = google_places[route].calls.last.request
        assert request.headers["X-Goog-Api-Key"] == PLACES_KEY
        assert PLACES_KEY not in str(request.url)


async def test_places_key_not_in_response_or_logs(
    client: AsyncClient,
    db: AsyncSession,
    google_places: respx.MockRouter,
    caplog: pytest.LogCaptureFixture,
) -> None:
    user = await create_user(db)
    google_places["details"].respond(status_code=500, text=f"error for key {PLACES_KEY}")
    caplog.set_level(logging.DEBUG)

    ok = await client.get(f"{PLACES}/autocomplete", params={"q": "파리"}, headers=user.headers)
    failed = await client.get(f"{PLACES}/{ORSAY_ID}", headers=user.headers)

    assert PLACES_KEY not in ok.text
    assert PLACES_KEY not in failed.text
    assert PLACES_KEY not in caplog.text


# --- T23: 비용 ------------------------------------------------------------------


async def test_place_details_field_mask_is_essentials_only(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    user = await create_user(db)

    await client.get(f"{PLACES}/{ORSAY_ID}", headers=user.headers)

    mask = google_places["details"].calls.last.request.headers["X-Goog-FieldMask"]
    assert mask == DETAILS_FIELD_MASK == "id,formattedAddress,location"
    # Pro 이상 필드가 들어가면 호출 전체가 비싼 요금이 된다 (5.1)
    for pro_field in ("displayName", "googleMapsUri", "rating", "photos", "*"):
        assert pro_field not in mask.split(",")


@pytest.fixture
async def limited_client(
    db: AsyncSession, migrated_database_url: str
) -> AsyncIterator[AsyncClient]:
    app = create_app(
        make_settings(
            database_url=migrated_database_url,
            places_autocomplete_per_minute=3,
            places_autocomplete_per_day=5,
            places_details_per_day=2,
            user_rate_limit_per_minute=20,
        )
    )
    async with client_for(app) as c:
        yield c


async def test_places_rate_limits(
    limited_client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    user = await create_user(db)
    other = await create_user(db)

    statuses = [
        (
            await limited_client.get(
                f"{PLACES}/autocomplete", params={"q": "파"}, headers=user.headers
            )
        ).status_code
        for _ in range(4)
    ]
    details = [
        (await limited_client.get(f"{PLACES}/{ORSAY_ID}", headers=user.headers)).status_code
        for _ in range(3)
    ]
    other_user = await limited_client.get(
        f"{PLACES}/autocomplete", params={"q": "파"}, headers=other.headers
    )

    assert statuses == [200, 200, 200, 429]
    assert details == [200, 200, 429]
    assert other_user.status_code == 200  # 사용자마다 따로 센다
    # 제한에 걸린 요청은 Google까지 가지 않는다
    assert google_places["autocomplete"].call_count == 4
    assert google_places["details"].call_count == 2


async def test_places_daily_limit(
    limited_client: AsyncClient,
    db: AsyncSession,
    google_places: respx.MockRouter,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    user = await create_user(db)
    clock = [1000.0]
    monkeypatch.setattr("travel_copilot.core.rate_limit.time.monotonic", lambda: clock[0])

    statuses = []
    for _ in range(6):
        response = await limited_client.get(
            f"{PLACES}/autocomplete", params={"q": "파"}, headers=user.headers
        )
        statuses.append(response.status_code)
        clock[0] += 61  # 분당 제한은 넘기지 않게 1분씩 지나게 한다

    assert statuses == [200] * 5 + [429]
    assert int(response.headers["retry-after"]) > 3600


async def test_user_rate_limit(limited_client: AsyncClient, db: AsyncSession) -> None:
    user = await create_user(db)

    statuses = [
        (await limited_client.get("/api/v1/trips", headers=user.headers)).status_code
        for _ in range(21)
    ]

    assert statuses[:20] == [200] * 20
    assert statuses[20] == 429


# --- T32: Google 요청 조작 -----------------------------------------------------


@pytest.mark.parametrize(
    ("path", "params"),
    [
        (f"{PLACES}/..%2Fplaces:autocomplete", {}),
        (f"{PLACES}/abc%3Fkey%3Dx", {}),
        (f"{PLACES}/abc.def", {}),
        (f"{PLACES}/{'a' * 256}", {}),
        (f"{PLACES}/{ORSAY_ID}", {"session_token": "short"}),
        (f"{PLACES}/{ORSAY_ID}", {"session_token": "a" * 20 + "/../x"}),
        (f"{PLACES}/autocomplete", {"q": "가" * 101}),
        (f"{PLACES}/autocomplete", {"q": "파리", "lat": 91, "lng": 0}),
        (f"{PLACES}/autocomplete", {"q": "파리", "session_token": "a?b" * 8}),
    ],
)
async def test_malformed_place_id_never_reaches_google(
    client: AsyncClient,
    db: AsyncSession,
    google_places: respx.MockRouter,
    path: str,
    params: dict[str, str | int],
) -> None:
    user = await create_user(db)

    response = await client.get(path, params=params, headers=user.headers)

    assert response.status_code in (404, 422)
    assert google_places["autocomplete"].call_count == 0
    assert google_places["details"].call_count == 0


async def test_malformed_place_id_in_item_never_reaches_google(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.post(
        f"/api/v1/trips/{trip['id']}/items",
        json={"day": "2026-12-21", "title": "x", "place_id": "../../v1/places:searchText"},
        headers=owner.headers,
    )

    assert response.status_code == 422
    assert google_places["details"].call_count == 0


# --- Google 응답은 외부 입력 ---------------------------------------------------


@pytest.mark.parametrize(
    "body",
    [
        place_details_body(location={"latitude": 999, "longitude": 0}),
        place_details_body(id="../evil"),
        {"id": ORSAY_ID},  # 좌표 없음
        ["not", "an", "object"],
    ],
)
async def test_invalid_google_response_is_rejected(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter, body: object
) -> None:
    user = await create_user(db)
    google_places["details"].respond(json=body)

    response = await client.get(f"{PLACES}/{ORSAY_ID}", headers=user.headers)

    assert response.status_code == 502
    assert response.json()["code"] == "upstream_error"


async def test_invalid_autocomplete_entries_are_dropped(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    user = await create_user(db)
    good = {
        "placePrediction": {"placeId": "ok_1", "structuredFormat": {"mainText": {"text": "좋음"}}}
    }
    google_places["autocomplete"].respond(
        json={
            "suggestions": [
                {
                    "placePrediction": {
                        "placeId": "../bad",
                        "structuredFormat": {"mainText": {"text": "x"}},
                    }
                },
                {"queryPrediction": {"text": {"text": "검색어 제안"}}},
                good,
            ]
        }
    )

    response = await client.get(f"{PLACES}/autocomplete", params={"q": "x"}, headers=user.headers)

    assert [s["place_id"] for s in response.json()["suggestions"]] == ["ok_1"]


async def test_google_error_body_not_exposed(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    user = await create_user(db)
    google_places["details"].respond(
        status_code=403, json={"error": {"message": "API key not valid. internal-detail-123"}}
    )

    response = await client.get(f"{PLACES}/{ORSAY_ID}", headers=user.headers)

    assert response.status_code == 502
    assert "internal-detail-123" not in response.text
    assert "API key" not in response.text


async def test_google_timeout_returns_502(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    import httpx

    user = await create_user(db)
    google_places["autocomplete"].side_effect = httpx.ConnectTimeout("timeout")

    response = await client.get(f"{PLACES}/autocomplete", params={"q": "x"}, headers=user.headers)

    assert response.status_code == 502


# --- 좌표 30일 (약관) ---------------------------------------------------------


async def test_stale_location_hidden(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    await add_item(client, owner, trip["id"], place_id=ORSAY_ID)
    await db.execute(
        text("UPDATE itinerary_items SET location_fetched_at = now() - interval '31 days'")
    )
    await db.commit()

    items = (await client.get(f"/api/v1/trips/{trip['id']}", headers=owner.headers)).json()["items"]

    assert items[0]["place_id"] == ORSAY_ID
    assert items[0]["location"] is None


async def test_expire_locations_job(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    old = await add_item(client, owner, trip["id"], place_id=ORSAY_ID, title="오래됨")
    await add_item(client, owner, trip["id"], place_id=ORSAY_ID, title="최근")
    await db.execute(
        text("UPDATE itinerary_items SET location_fetched_at = :t WHERE id = :id"),
        {"t": datetime.now(UTC) - timedelta(days=31), "id": old["id"]},
    )
    await db.commit()

    count = await expire_locations(db)

    assert count == 1
    rows = (
        await db.execute(
            text("SELECT title, lat, location_fetched_at FROM itinerary_items ORDER BY position")
        )
    ).all()
    assert [(r[0], r[1] is None, r[2] is None) for r in rows] == [
        ("오래됨", True, True),
        ("최근", False, False),
    ]


async def test_details_url_is_fixed_endpoint(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    user = await create_user(db)

    await client.get(f"{PLACES}/{ORSAY_ID}", headers=user.headers)

    url = google_places["details"].calls.last.request.url
    assert str(url).startswith(f"{PLACES_BASE_URL}/places/{ORSAY_ID}?")
