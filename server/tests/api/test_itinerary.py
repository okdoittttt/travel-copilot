"""일정 항목·장소 API 동작 테스트. 권한·공격은 tests/security/."""

import json
from typing import Any

import respx
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import (
    ORSAY_ID,
    add_item,
    client_for,
    create_trip,
    create_user,
    make_settings,
)
from travel_copilot.main import create_app

TRIPS = "/api/v1/trips"


async def _snapshot_items(client: AsyncClient, user: Any, trip_id: str) -> list[dict[str, Any]]:
    response = await client.get(f"{TRIPS}/{trip_id}", headers=user.headers)
    items: list[dict[str, Any]] = response.json()["items"]
    return items


def _titles(items: list[dict[str, Any]], day: str) -> list[str]:
    return [i["title"] for i in sorted(items, key=lambda i: i["position"]) if i["day"] == day]


async def test_create_item_appends_and_appears_in_snapshot(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    first = await add_item(client, owner, trip["id"], title="숙소", start_time="09:00")
    second = await add_item(client, owner, trip["id"], title="  미술관 ", memo="야간\n개장")

    assert first["position"] == 0
    assert second["position"] == 1
    assert second["title"] == "미술관"
    assert set(first) == {
        "id",
        "day",
        "position",
        "title",
        "memo",
        "place_id",
        "location",
        "start_time",
        "stay_minutes",
        "travel_mode",
        "version",
        "updated_at",
    }
    assert first["start_time"] == "09:00"
    items = await _snapshot_items(client, owner, trip["id"])
    assert _titles(items, "2026-12-21") == ["숙소", "미술관"]


async def test_create_item_outside_trip_period_returns_422(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)  # 12-20 ~ 12-27

    response = await client.post(
        f"{TRIPS}/{trip['id']}/items",
        json={"day": "2026-12-28", "title": "밖"},
        headers=owner.headers,
    )

    assert response.status_code == 422
    assert response.json()["code"] == "validation_error"


async def test_day_item_limit(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    for i in range(50):
        await add_item(client, owner, trip["id"], title=f"항목 {i}")

    response = await client.post(
        f"{TRIPS}/{trip['id']}/items",
        json={"day": "2026-12-21", "title": "51번째"},
        headers=owner.headers,
    )

    assert response.status_code == 409
    assert response.json()["code"] == "day_item_limit"


async def test_update_item_and_clear_fields(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    item = await add_item(client, owner, trip["id"], memo="메모", stay_minutes=60)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}/items/{item['id']}",
        json={"version": 1, "title": "새 제목", "memo": None, "travel_mode": "walk"},
        headers=owner.headers,
    )

    assert response.status_code == 200
    body = response.json()
    assert body["version"] == 2
    assert body["title"] == "새 제목"
    assert body["memo"] is None
    assert body["stay_minutes"] == 60
    assert body["travel_mode"] == "walk"


async def test_move_item_to_other_day_renumbers(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    a = await add_item(client, owner, trip["id"], title="A")
    b = await add_item(client, owner, trip["id"], title="B")
    await add_item(client, owner, trip["id"], title="C")
    await add_item(client, owner, trip["id"], day="2026-12-22", title="X")

    response = await client.patch(
        f"{TRIPS}/{trip['id']}/items/{b['id']}",
        json={"version": b["version"], "day": "2026-12-22"},
        headers=owner.headers,
    )

    assert response.status_code == 200
    assert response.json()["position"] == 1
    items = await _snapshot_items(client, owner, trip["id"])
    assert _titles(items, "2026-12-21") == ["A", "C"]
    assert _titles(items, "2026-12-22") == ["X", "B"]
    positions = sorted(i["position"] for i in items if i["day"] == "2026-12-21")
    assert positions == [0, 1]
    assert a["id"] in {i["id"] for i in items}


async def test_delete_item_renumbers(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    a = await add_item(client, owner, trip["id"], title="A")
    await add_item(client, owner, trip["id"], title="B")

    response = await client.delete(
        f"{TRIPS}/{trip['id']}/items/{a['id']}?version=1", headers=owner.headers
    )

    assert response.status_code == 204
    items = await _snapshot_items(client, owner, trip["id"])
    assert [(i["title"], i["position"]) for i in items] == [("B", 0)]


async def test_reorder_day(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    a = await add_item(client, owner, trip["id"], title="A")
    b = await add_item(client, owner, trip["id"], title="B")
    c = await add_item(client, owner, trip["id"], title="C")

    response = await client.put(
        f"{TRIPS}/{trip['id']}/days/2026-12-21/order",
        json={"items": [{"id": i["id"], "version": i["version"]} for i in (c, a, b)]},
        headers=owner.headers,
    )

    assert response.status_code == 200
    body = response.json()
    assert body["date"] == "2026-12-21"
    assert [(i["title"], i["position"], i["version"]) for i in body["items"]] == [
        ("C", 0, 2),
        ("A", 1, 2),
        ("B", 2, 2),
    ]


async def test_reorder_only_bumps_moved_items(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    a = await add_item(client, owner, trip["id"], title="A")
    b = await add_item(client, owner, trip["id"], title="B")
    c = await add_item(client, owner, trip["id"], title="C")

    body = (
        await client.put(
            f"{TRIPS}/{trip['id']}/days/2026-12-21/order",
            json={"items": [{"id": i["id"], "version": 1} for i in (a, c, b)]},
            headers=owner.headers,
        )
    ).json()

    assert {i["title"]: i["version"] for i in body["items"]} == {"A": 1, "C": 2, "B": 2}


async def test_reorder_missing_item_returns_409(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    a = await add_item(client, owner, trip["id"], title="A")
    await add_item(client, owner, trip["id"], title="B")

    response = await client.put(
        f"{TRIPS}/{trip['id']}/days/2026-12-21/order",
        json={"items": [{"id": a["id"], "version": 1}]},
        headers=owner.headers,
    )

    assert response.status_code == 409
    assert response.json()["code"] == "order_mismatch"
    assert [i["title"] for i in response.json()["current"]["items"]] == ["A", "B"]


async def test_shrinking_trip_with_items_outside_returns_409(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)  # 12-20 ~ 12-27
    await add_item(client, owner, trip["id"], day="2026-12-26")
    await add_item(client, owner, trip["id"], day="2026-12-26")

    response = await client.patch(
        f"{TRIPS}/{trip['id']}",
        json={"version": 1, "end_date": "2026-12-25"},
        headers=owner.headers,
    )

    assert response.status_code == 409
    assert response.json()["code"] == "trip_period_conflict"
    assert "12/26 2개" in response.json()["detail"]


async def test_shrinking_trip_without_items_outside_succeeds(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    await add_item(client, owner, trip["id"], day="2026-12-21")

    response = await client.patch(
        f"{TRIPS}/{trip['id']}",
        json={"version": 1, "end_date": "2026-12-25"},
        headers=owner.headers,
    )

    assert response.status_code == 200


async def test_delete_trip_deletes_items(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    await add_item(client, owner, trip["id"])

    await client.delete(f"{TRIPS}/{trip['id']}?version=1", headers=owner.headers)

    count = await db.scalar(text("SELECT count(*) FROM itinerary_items"))
    assert count == 0


# --- 장소 ---------------------------------------------------------------------


async def test_autocomplete(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    user = await create_user(db)

    response = await client.get(
        "/api/v1/places/autocomplete",
        params={"q": "오르세", "session_token": "a" * 32, "lat": 48.8, "lng": 2.3},
        headers=user.headers,
    )

    assert response.status_code == 200
    assert response.json() == {
        "suggestions": [
            {"place_id": ORSAY_ID, "name": "오르세 미술관", "secondary": "프랑스 파리"}
        ],
        "attribution": "Google Maps",
    }
    sent = google_places["autocomplete"].calls.last.request
    body = json.loads(sent.content)
    assert body["input"] == "오르세"
    assert body["sessionToken"] == "a" * 32
    assert body["languageCode"] == "ko"
    assert body["locationBias"]["circle"]["center"] == {"latitude": 48.8, "longitude": 2.3}


async def test_place_details(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    user = await create_user(db)

    response = await client.get(
        f"/api/v1/places/{ORSAY_ID}", params={"session_token": "b" * 32}, headers=user.headers
    )

    assert response.status_code == 200
    body = response.json()
    assert body["place_id"] == ORSAY_ID
    assert body["location"] == {"lat": 48.86, "lng": 2.3266}
    assert body["maps_url"].endswith(f"query_place_id={ORSAY_ID}")
    assert body["attribution"] == "Google Maps"
    assert "name" not in body
    assert google_places["details"].calls.last.request.url.params["sessionToken"] == "b" * 32


async def test_item_with_place_uses_location_from_selection(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    await client.get(f"/api/v1/places/{ORSAY_ID}", headers=owner.headers)
    assert google_places["details"].call_count == 1

    item = await add_item(client, owner, trip["id"], place_id=ORSAY_ID)

    # 장소를 고를 때 받은 좌표를 써서 Google을 다시 부르지 않는다
    assert google_places["details"].call_count == 1
    assert item["place_id"] == ORSAY_ID
    assert item["location"] == {"lat": 48.86, "lng": 2.3266}


async def test_item_with_place_fetches_location_when_not_cached(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    item = await add_item(client, owner, trip["id"], place_id=ORSAY_ID)

    assert google_places["details"].call_count == 1
    assert item["location"] == {"lat": 48.86, "lng": 2.3266}


async def test_removing_place_clears_location(
    client: AsyncClient, db: AsyncSession, google_places: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    item = await add_item(client, owner, trip["id"], place_id=ORSAY_ID)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}/items/{item['id']}",
        json={"version": 1, "place_id": None},
        headers=owner.headers,
    )

    assert response.json()["place_id"] is None
    assert response.json()["location"] is None


async def test_places_without_key_returns_503(db: AsyncSession, migrated_database_url: str) -> None:
    user = await create_user(db)
    app = create_app(make_settings(database_url=migrated_database_url, google_places_api_key=""))
    async with client_for(app) as client:
        places = await client.get(
            "/api/v1/places/autocomplete", params={"q": "파리"}, headers=user.headers
        )
        trip = await create_trip(client, user)
        # 장소 없는 일정은 키 없이도 된다
        item = await add_item(client, user, trip["id"], title="메모만")

    assert places.status_code == 503
    assert places.json()["code"] == "places_unavailable"
    assert item["place_id"] is None
