"""T06·T07·T08·T29: 일정 항목 인가 (features/itinerary.md 8절).

비멤버 404·라우트 전수 검사는 test_trips_authz.py의 케이스 목록에 포함돼 있다.
"""

import asyncio
from typing import Any

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import add_item, add_member, create_trip, create_user
from travel_copilot.trips.models import TripRole

TRIPS = "/api/v1/trips"


async def _snapshot(client: AsyncClient, user: Any, trip_id: str) -> dict[str, Any]:
    body: dict[str, Any] = (await client.get(f"{TRIPS}/{trip_id}", headers=user.headers)).json()
    return body


async def test_item_of_other_trip_returns_404(client: AsyncClient, db: AsyncSession) -> None:
    alice = await create_user(db)
    bob = await create_user(db)
    alices_trip = await create_trip(client, alice)
    bobs_trip = await create_trip(client, bob)
    bobs_item = await add_item(client, bob, bobs_trip["id"], title="밥의 일정")

    # 내 여행 경로에 남의 항목 ID를 넣는다 (08-conventions S2)
    patch = await client.patch(
        f"{TRIPS}/{alices_trip['id']}/items/{bobs_item['id']}",
        json={"version": 1, "title": "탈취"},
        headers=alice.headers,
    )
    delete = await client.delete(
        f"{TRIPS}/{alices_trip['id']}/items/{bobs_item['id']}?version=1", headers=alice.headers
    )

    assert patch.status_code == delete.status_code == 404
    items = (await _snapshot(client, bob, bobs_trip["id"]))["items"]
    assert [(i["title"], i["version"]) for i in items] == [("밥의 일정", 1)]


async def test_reorder_with_foreign_item_is_rejected(client: AsyncClient, db: AsyncSession) -> None:
    alice = await create_user(db)
    bob = await create_user(db)
    alices_trip = await create_trip(client, alice)
    bobs_trip = await create_trip(client, bob)
    mine = await add_item(client, alice, alices_trip["id"], title="내 것")
    theirs = await add_item(client, bob, bobs_trip["id"], title="남의 것")

    response = await client.put(
        f"{TRIPS}/{alices_trip['id']}/days/2026-12-21/order",
        json={"items": [{"id": theirs["id"], "version": 1}, {"id": mine["id"], "version": 1}]},
        headers=alice.headers,
    )

    assert response.status_code == 409
    assert response.json()["code"] == "order_mismatch"
    assert [i["title"] for i in response.json()["current"]["items"]] == ["내 것"]
    bob_items = (await _snapshot(client, bob, bobs_trip["id"]))["items"]
    assert [(i["position"], i["version"]) for i in bob_items] == [(0, 1)]


async def test_reorder_with_duplicate_ids_is_rejected(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    a = await add_item(client, owner, trip["id"])
    await add_item(client, owner, trip["id"])

    response = await client.put(
        f"{TRIPS}/{trip['id']}/days/2026-12-21/order",
        json={"items": [{"id": a["id"], "version": 1}, {"id": a["id"], "version": 1}]},
        headers=owner.headers,
    )

    assert response.status_code == 409


@pytest.mark.parametrize("action", ["create", "update", "delete", "reorder"])
async def test_viewer_cannot_modify_items(
    client: AsyncClient, db: AsyncSession, action: str
) -> None:
    owner = await create_user(db)
    viewer = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], viewer, TripRole.VIEWER)
    item = await add_item(client, owner, trip["id"])
    base = f"{TRIPS}/{trip['id']}"
    requests = {
        "create": ("POST", f"{base}/items", {"day": "2026-12-21", "title": "몰래"}),
        "update": ("PATCH", f"{base}/items/{item['id']}", {"version": 1, "title": "몰래"}),
        "delete": ("DELETE", f"{base}/items/{item['id']}?version=1", None),
        "reorder": (
            "PUT",
            f"{base}/days/2026-12-21/order",
            {"items": [{"id": item["id"], "version": 1}]},
        ),
    }
    method, url, body = requests[action]

    response = await client.request(method, url, json=body, headers=viewer.headers)

    assert response.status_code == 403
    items = (await _snapshot(client, owner, trip["id"]))["items"]
    assert [(i["title"], i["version"]) for i in items] == [("일정", 1)]


async def test_removed_member_cannot_touch_items(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    editor = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], editor, TripRole.EDITOR)
    item = await add_item(client, editor, trip["id"])
    await client.delete(f"{TRIPS}/{trip['id']}/members/{editor.id}", headers=owner.headers)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}/items/{item['id']}",
        json={"version": 1, "title": "복수"},
        headers=editor.headers,
    )

    assert response.status_code == 404


async def test_update_item_with_stale_version_returns_409(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    editor = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], editor, TripRole.EDITOR)
    item = await add_item(client, owner, trip["id"])
    url = f"{TRIPS}/{trip['id']}/items/{item['id']}"
    await client.patch(url, json={"version": 1, "title": "먼저"}, headers=owner.headers)

    late = await client.patch(url, json={"version": 1, "title": "나중"}, headers=editor.headers)

    assert late.status_code == 409
    assert late.json()["code"] == "version_conflict"
    assert late.json()["current"]["title"] == "먼저"


async def test_concurrent_adds_get_distinct_positions(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    responses = await asyncio.gather(
        *(
            client.post(
                f"{TRIPS}/{trip['id']}/items",
                json={"day": "2026-12-21", "title": f"동시 {i}"},
                headers=owner.headers,
            )
            for i in range(5)
        )
    )

    assert [r.status_code for r in responses] == [201] * 5
    assert sorted(r.json()["position"] for r in responses) == [0, 1, 2, 3, 4]


async def test_client_supplied_location_is_rejected(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    item = await add_item(client, owner, trip["id"])

    create = await client.post(
        f"{TRIPS}/{trip['id']}/items",
        json={"day": "2026-12-21", "title": "가짜", "location": {"lat": 0, "lng": 0}},
        headers=owner.headers,
    )
    update = await client.patch(
        f"{TRIPS}/{trip['id']}/items/{item['id']}",
        json={"version": 1, "lat": 0, "lng": 0},
        headers=owner.headers,
    )

    assert create.status_code == update.status_code == 422
