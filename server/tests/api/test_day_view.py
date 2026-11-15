"""하루 일정 + 이동 구간 API 테스트 (features/routes-map.md 6절)."""

from typing import Any

import respx
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import (
    EIFFEL_ID,
    LOUVRE_ID,
    ORSAY_ID,
    add_item,
    client_for,
    create_trip,
    create_user,
    make_settings,
)
from travel_copilot.main import create_app

DAY = "2026-12-21"


def _day_url(trip_id: str, day: str = DAY) -> str:
    return f"/api/v1/trips/{trip_id}/days/{day}"


async def test_day_view_with_legs(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    a = await add_item(client, owner, trip["id"], title="오르세", place_id=ORSAY_ID)
    b = await add_item(
        client, owner, trip["id"], title="루브르", place_id=LOUVRE_ID, travel_mode="walk"
    )
    c = await add_item(client, owner, trip["id"], title="메모만", travel_mode="walk")
    d = await add_item(client, owner, trip["id"], title="에펠", place_id=EIFFEL_ID)

    response = await client.get(_day_url(trip["id"]), headers=owner.headers)

    assert response.status_code == 200
    body = response.json()
    assert body["date"] == DAY
    assert [i["title"] for i in body["items"]] == ["오르세", "루브르", "메모만", "에펠"]
    assert body["legs"] == [
        {
            "from_item_id": a["id"],
            "to_item_id": b["id"],
            "mode": "walk",
            "status": "ok",
            "duration_seconds": 1260,
            "distance_meters": 3900,
        },
        {
            "from_item_id": b["id"],
            "to_item_id": c["id"],
            "mode": "walk",
            "status": "no_location",
            "duration_seconds": None,
            "distance_meters": None,
        },
        {
            "from_item_id": c["id"],
            "to_item_id": d["id"],
            "mode": None,
            "status": "no_location",
            "duration_seconds": None,
            "distance_meters": None,
        },
    ]
    assert google_routes["routes"].call_count == 1


async def test_leg_without_mode(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    await add_item(client, owner, trip["id"], place_id=ORSAY_ID)
    await add_item(client, owner, trip["id"], place_id=LOUVRE_ID)

    legs = (await client.get(_day_url(trip["id"]), headers=owner.headers)).json()["legs"]

    assert [leg["status"] for leg in legs] == ["no_mode"]
    assert google_routes["routes"].call_count == 0


async def test_empty_day(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    body = (await client.get(_day_url(trip["id"]), headers=owner.headers)).json()

    assert body == {"date": DAY, "items": [], "legs": []}


async def test_day_outside_trip_returns_422(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.get(_day_url(trip["id"], "2027-01-30"), headers=owner.headers)

    assert response.status_code == 422


async def test_viewer_can_see_day(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    from tests.conftest import add_member
    from travel_copilot.trips.models import TripRole

    owner = await create_user(db)
    viewer = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], viewer, TripRole.VIEWER)
    await add_item(client, owner, trip["id"])

    response = await client.get(_day_url(trip["id"]), headers=viewer.headers)

    assert response.status_code == 200


async def test_stale_location_is_refreshed(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    await add_item(client, owner, trip["id"], place_id=ORSAY_ID)
    await db.execute(
        text("UPDATE itinerary_items SET location_fetched_at = now() - interval '31 days'")
    )
    await db.commit()
    calls_before = google_routes["details"].call_count

    body = (await client.get(_day_url(trip["id"]), headers=owner.headers)).json()

    # 캐시(10분)에 좌표가 남아 있으면 Google을 다시 부르지 않을 수 있다. 핵심은 DB 갱신
    assert google_routes["details"].call_count >= calls_before
    assert body["items"][0]["location"] == {"lat": 48.86, "lng": 2.3266}
    fetched = await db.scalar(
        text("SELECT location_fetched_at > now() - interval '1 minute' FROM itinerary_items")
    )
    assert fetched is True


async def test_location_refresh_does_not_overwrite_changed_place(
    client: AsyncClient, db: AsyncSession, google_routes: respx.MockRouter
) -> None:
    import uuid
    from datetime import UTC, datetime

    from travel_copilot.itinerary import repository

    owner = await create_user(db)
    trip = await create_trip(client, owner)
    item = await add_item(client, owner, trip["id"], place_id=ORSAY_ID)
    await db.execute(text("UPDATE itinerary_items SET google_place_id = 'other_place'"))
    await db.commit()

    await repository.update_location_if_place(
        db, uuid.UUID(item["id"]), ORSAY_ID, 1.0, 2.0, datetime.now(UTC)
    )
    await db.commit()

    lat = await db.scalar(text("SELECT lat FROM itinerary_items"))
    assert float(lat) == 48.86  # 옛 장소 좌표로 덮어쓰지 않았다


async def test_without_server_key_all_legs_unavailable(
    db: AsyncSession, migrated_database_url: str, google_routes: respx.MockRouter
) -> None:
    owner = await create_user(db)
    with_key = create_app(make_settings(database_url=migrated_database_url))
    async with client_for(with_key) as client:
        trip = await create_trip(client, owner)
        await add_item(client, owner, trip["id"], place_id=ORSAY_ID)
        await add_item(client, owner, trip["id"], place_id=LOUVRE_ID, travel_mode="drive")

    no_key = create_app(make_settings(database_url=migrated_database_url, google_places_api_key=""))
    async with client_for(no_key) as client:
        response = await client.get(_day_url(trip["id"]), headers=owner.headers)

    assert response.status_code == 200
    body: dict[str, Any] = response.json()
    assert [leg["status"] for leg in body["legs"]] == ["unavailable"]
    assert len(body["items"]) == 2
