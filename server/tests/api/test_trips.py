"""여행·멤버 API 동작 테스트. 권한·공격 시나리오는 tests/security/test_trips_authz.py."""

from httpx import AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import TRIP_BODY, add_member, create_trip, create_user
from travel_copilot.trips.models import TripMember, TripRole

TRIPS = "/api/v1/trips"


# --- 여행 --------------------------------------------------------------------


async def test_create_trip_makes_creator_owner(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)

    trip = await create_trip(client, owner)

    assert set(trip) == {
        "id",
        "title",
        "destination",
        "start_date",
        "end_date",
        "timezone",
        "version",
        "my_role",
        "member_count",
        "updated_at",
    }
    assert trip["my_role"] == "owner"
    assert trip["member_count"] == 1
    assert trip["version"] == 1
    assert trip["title"] == TRIP_BODY["title"]


async def test_create_trip_without_token_returns_401(client: AsyncClient) -> None:
    response = await client.post(TRIPS, json=TRIP_BODY)

    assert response.status_code == 401
    assert response.json()["code"] == "token_missing"


async def test_create_trip_with_invalid_period_returns_422(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)

    response = await client.post(
        TRIPS, json={**TRIP_BODY, "end_date": "2027-03-01"}, headers=owner.headers
    )

    assert response.status_code == 422
    assert response.json()["code"] == "validation_error"


async def test_get_trip_snapshot(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db, "주인")
    viewer = await create_user(db, "부모님")
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], viewer, TripRole.VIEWER)

    response = await client.get(f"{TRIPS}/{trip['id']}", headers=viewer.headers)

    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"trip", "members"}
    assert body["trip"]["my_role"] == "viewer"
    assert body["trip"]["member_count"] == 2
    assert [(m["display_name"], m["role"]) for m in body["members"]] == [
        ("주인", "owner"),
        ("부모님", "viewer"),
    ]
    assert set(body["members"][0]) == {"user_id", "display_name", "role", "joined_at"}


async def test_update_trip_bumps_version(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}",
        json={"version": 1, "title": "  파리 + 런던 ", "end_date": "2026-12-30"},
        headers=owner.headers,
    )

    assert response.status_code == 200
    body = response.json()
    assert body["version"] == 2
    assert body["title"] == "파리 + 런던"
    assert body["end_date"] == "2026-12-30"
    assert body["destination"] == TRIP_BODY["destination"]


async def test_editor_can_update_trip(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    editor = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], editor, TripRole.EDITOR)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}", json={"version": 1, "title": "수정"}, headers=editor.headers
    )

    assert response.status_code == 200
    assert response.json()["my_role"] == "editor"


async def test_update_trip_period_checked_with_existing_dates(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)  # 12-20 ~ 12-27

    response = await client.patch(
        f"{TRIPS}/{trip['id']}",
        json={"version": 1, "start_date": "2026-12-28"},
        headers=owner.headers,
    )

    assert response.status_code == 422
    assert response.json()["code"] == "validation_error"


async def test_update_trip_without_changes_returns_422(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}", json={"version": 1}, headers=owner.headers
    )

    assert response.status_code == 422


async def test_delete_trip_removes_members(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    editor = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], editor, TripRole.EDITOR)

    response = await client.delete(f"{TRIPS}/{trip['id']}?version=1", headers=owner.headers)

    assert response.status_code == 204
    assert (await client.get(f"{TRIPS}/{trip['id']}", headers=owner.headers)).status_code == 404
    count = await db.scalar(select(func.count()).select_from(TripMember))
    assert count == 0


async def test_delete_trip_with_stale_version_returns_409(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    await client.patch(
        f"{TRIPS}/{trip['id']}", json={"version": 1, "title": "수정"}, headers=owner.headers
    )

    response = await client.delete(f"{TRIPS}/{trip['id']}?version=1", headers=owner.headers)

    assert response.status_code == 409
    assert response.json()["current"]["version"] == 2


async def test_delete_trip_without_version_returns_422(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.delete(f"{TRIPS}/{trip['id']}", headers=owner.headers)

    assert response.status_code == 422


async def test_invalid_trip_id_returns_422(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)

    response = await client.get(f"{TRIPS}/not-a-uuid", headers=owner.headers)

    assert response.status_code == 422


# --- 목록 --------------------------------------------------------------------


async def test_list_trips_orders_by_start_date_and_pages(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    starts = ["2026-01-10", "2026-05-01", "2025-08-15", "2026-05-01", "2027-02-01"]
    for start in starts:
        await create_trip(client, owner, start_date=start, end_date=start)

    seen: list[str] = []
    cursor = None
    pages = 0
    while True:
        params = {"limit": 2} | ({"cursor": cursor} if cursor else {})
        response = await client.get(TRIPS, params=params, headers=owner.headers)
        assert response.status_code == 200
        body = response.json()
        seen += [item["start_date"] for item in body["items"]]
        pages += 1
        cursor = body["next_cursor"]
        if cursor is None:
            break

    assert pages == 3
    assert seen == sorted(starts, reverse=True)


async def test_list_trips_with_tampered_cursor_returns_422(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)

    response = await client.get(TRIPS, params={"cursor": "abc"}, headers=owner.headers)

    assert response.status_code == 422
    assert response.json()["code"] == "validation_error"


async def test_list_trips_limit_bounds(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)

    assert (await client.get(TRIPS, params={"limit": 0}, headers=owner.headers)).status_code == 422
    assert (await client.get(TRIPS, params={"limit": 51}, headers=owner.headers)).status_code == 422


# --- 멤버 --------------------------------------------------------------------


async def test_owner_changes_member_role(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    member = await create_user(db, "친구")
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], member, TripRole.EDITOR)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}/members/{member.id}", json={"role": "viewer"}, headers=owner.headers
    )

    assert response.status_code == 200
    assert response.json()["role"] == "viewer"
    assert response.json()["display_name"] == "친구"


async def test_owner_role_cannot_be_changed(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}/members/{owner.id}", json={"role": "editor"}, headers=owner.headers
    )

    assert response.status_code == 409
    assert response.json()["code"] == "owner_role_locked"


async def test_change_role_of_non_member_returns_404(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    stranger = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}/members/{stranger.id}",
        json={"role": "viewer"},
        headers=owner.headers,
    )

    assert response.status_code == 404


async def test_owner_removes_member(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    member = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], member, TripRole.EDITOR)

    response = await client.delete(
        f"{TRIPS}/{trip['id']}/members/{member.id}", headers=owner.headers
    )

    assert response.status_code == 204
    snapshot = (await client.get(f"{TRIPS}/{trip['id']}", headers=owner.headers)).json()
    assert [m["user_id"] for m in snapshot["members"]] == [str(owner.id)]


async def test_member_leaves_trip(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    viewer = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], viewer, TripRole.VIEWER)

    response = await client.delete(
        f"{TRIPS}/{trip['id']}/members/{viewer.id}", headers=viewer.headers
    )

    assert response.status_code == 204
    trips = (await client.get(TRIPS, headers=viewer.headers)).json()["items"]
    assert trips == []


async def test_owner_cannot_leave(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.delete(
        f"{TRIPS}/{trip['id']}/members/{owner.id}", headers=owner.headers
    )

    assert response.status_code == 409
    assert response.json()["code"] == "owner_cannot_leave"


async def test_transfer_ownership(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    editor = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], editor, TripRole.EDITOR)

    response = await client.post(
        f"{TRIPS}/{trip['id']}/transfer-ownership",
        json={"user_id": str(editor.id)},
        headers=owner.headers,
    )

    assert response.status_code == 200
    body = response.json()
    assert body["trip"]["my_role"] == "editor"
    roles = {m["user_id"]: m["role"] for m in body["members"]}
    assert roles == {str(owner.id): "editor", str(editor.id): "owner"}


async def test_transfer_ownership_to_self_returns_400(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.post(
        f"{TRIPS}/{trip['id']}/transfer-ownership",
        json={"user_id": str(owner.id)},
        headers=owner.headers,
    )

    assert response.status_code == 400


async def test_transfer_ownership_to_non_member_returns_404(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    stranger = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.post(
        f"{TRIPS}/{trip['id']}/transfer-ownership",
        json={"user_id": str(stranger.id)},
        headers=owner.headers,
    )

    assert response.status_code == 404
    owners = await db.scalar(
        select(func.count()).select_from(TripMember).where(TripMember.role == TripRole.OWNER)
    )
    assert owners == 1
