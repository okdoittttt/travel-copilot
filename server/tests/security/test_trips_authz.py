"""T06·T07·T08·T29: 여행 인가 (features/trips.md 8절).

권한 확인을 빼면 이 파일의 테스트가 실패해야 한다 (방어 제거 시험).
"""

import asyncio
import uuid
from collections.abc import Iterator
from typing import Any

import pytest
from fastapi.dependencies.models import Dependant
from fastapi.routing import APIRoute
from httpx import AsyncClient
from sqlalchemy import func, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

from tests.conftest import (
    TRIP_BODY,
    SeededUser,
    add_member,
    create_trip,
    create_user,
    make_settings,
)
from travel_copilot.main import API_PREFIX, ROUTERS, create_app
from travel_copilot.trips.dependencies import TRIP_GUARD_MARKER
from travel_copilot.trips.models import TripMember, TripRole

TRIPS = "/api/v1/trips"

# `{trip_id}`가 들어간 모든 라우트. 새 라우트를 추가하면 여기에도 넣어야
# test_trip_route_cases_cover_all_routes가 통과한다.
TRIP_ROUTE_CASES: list[tuple[str, str, dict[str, Any] | None]] = [
    ("GET", "/api/v1/trips/{trip_id}", None),
    ("PATCH", "/api/v1/trips/{trip_id}", {"version": 1, "title": "탈취"}),
    ("DELETE", "/api/v1/trips/{trip_id}", None),
    ("PATCH", "/api/v1/trips/{trip_id}/members/{user_id}", {"role": "viewer"}),
    ("DELETE", "/api/v1/trips/{trip_id}/members/{user_id}", None),
    ("POST", "/api/v1/trips/{trip_id}/transfer-ownership", {"user_id": "{user_id}"}),
]


def _trip_routes() -> list[tuple[str, APIRoute]]:
    """등록된 라우터에서 `{trip_id}`가 들어간 라우트를 (전체 경로, 라우트)로 모은다."""
    return [
        (API_PREFIX + route.path, route)
        for router in ROUTERS
        for route in router.routes
        if isinstance(route, APIRoute) and "{trip_id}" in route.path
    ]


def _openapi_trip_operations() -> set[tuple[str, str]]:
    """실제 앱이 노출하는 `{trip_id}` 경로와 메서드 (ROUTERS 밖에서 등록된 라우트도 잡는다)."""
    schema = create_app(make_settings()).openapi()
    return {
        (method.upper(), path)
        for path, operations in schema["paths"].items()
        if "{trip_id}" in path
        for method in operations
    }


def _walk(dependant: Dependant) -> Iterator[Dependant]:
    for dependency in dependant.dependencies:
        yield dependency
        yield from _walk(dependency)


def _fill(template: str, trip_id: str, user_id: uuid.UUID) -> str:
    return template.replace("{trip_id}", trip_id).replace("{user_id}", str(user_id))


async def _call(
    client: AsyncClient,
    case: tuple[str, str, dict[str, Any] | None],
    trip_id: str,
    target: uuid.UUID,
    user: SeededUser,
) -> Any:
    method, template, body = case
    url = _fill(template, trip_id, target)
    if method == "DELETE" and template == "/api/v1/trips/{trip_id}":
        url += "?version=1"
    json = {
        k: _fill(v, trip_id, target) if isinstance(v, str) else v for k, v in (body or {}).items()
    }
    return await client.request(method, url, json=json or None, headers=user.headers)


async def _owner_count(db: AsyncSession, trip_id: str) -> int:
    count = await db.scalar(
        select(func.count())
        .select_from(TripMember)
        .where(TripMember.trip_id == uuid.UUID(trip_id), TripMember.role == TripRole.OWNER)
    )
    return int(count or 0)


# --- T06: 모든 여행 라우트에 권한 확인 ---------------------------------------


def test_all_trip_routes_require_membership() -> None:
    routes = _trip_routes()

    assert routes, "여행 라우트를 찾지 못했다"
    missing = [
        f"{sorted(r.methods or ())} {path}"
        for path, r in routes
        if not any(getattr(d.call, TRIP_GUARD_MARKER, False) for d in _walk(r.dependant))
    ]
    assert missing == [], f"권한 확인 의존성이 없는 라우트: {missing}"


def test_trip_route_cases_cover_all_routes() -> None:
    registered = {(m, path) for path, r in _trip_routes() for m in r.methods or ()}

    # 검사 대상(ROUTERS)과 실제 앱, 테스트 케이스 목록이 모두 같아야 한다
    assert registered == _openapi_trip_operations()
    assert registered == {(m, p) for m, p, _ in TRIP_ROUTE_CASES}


@pytest.mark.parametrize("case", TRIP_ROUTE_CASES, ids=lambda c: f"{c[0]} {c[1]}")
async def test_non_member_gets_404_on_every_trip_route(
    client: AsyncClient, db: AsyncSession, case: tuple[str, str, dict[str, Any] | None]
) -> None:
    owner = await create_user(db)
    stranger = await create_user(db)
    trip = await create_trip(client, owner)

    response = await _call(client, case, trip["id"], owner.id, stranger)

    assert response.status_code == 404
    assert response.json()["code"] == "not_found"
    # 아무것도 바뀌지 않았다
    snapshot = (await client.get(f"{TRIPS}/{trip['id']}", headers=owner.headers)).json()
    assert snapshot["trip"]["version"] == 1
    assert [(m["user_id"], m["role"]) for m in snapshot["members"]] == [(str(owner.id), "owner")]


@pytest.mark.parametrize("case", TRIP_ROUTE_CASES, ids=lambda c: f"{c[0]} {c[1]}")
async def test_non_member_and_missing_trip_responses_are_identical(
    client: AsyncClient, db: AsyncSession, case: tuple[str, str, dict[str, Any] | None]
) -> None:
    owner = await create_user(db)
    stranger = await create_user(db)
    trip = await create_trip(client, owner)

    existing = await _call(client, case, trip["id"], owner.id, stranger)
    missing = await _call(client, case, str(uuid.uuid4()), owner.id, stranger)

    assert existing.status_code == missing.status_code == 404
    assert existing.json() == missing.json()


async def test_list_trips_returns_only_my_trips(client: AsyncClient, db: AsyncSession) -> None:
    alice = await create_user(db)
    bob = await create_user(db)
    mine = await create_trip(client, alice, title="내 여행")
    await create_trip(client, bob, title="남의 여행")

    items = (await client.get(TRIPS, headers=alice.headers)).json()["items"]

    assert [item["id"] for item in items] == [mine["id"]]


async def test_owner_cannot_manage_member_of_other_trip(
    client: AsyncClient, db: AsyncSession
) -> None:
    alice = await create_user(db)
    bob = await create_user(db)
    bobs_friend = await create_user(db)
    alices_trip = await create_trip(client, alice)
    bobs_trip = await create_trip(client, bob)
    await add_member(db, bobs_trip["id"], bobs_friend, TripRole.EDITOR)

    # 내 여행 경로에 남의 여행 멤버 ID를 넣어도 그 멤버십에 닿지 않는다
    response = await client.delete(
        f"{TRIPS}/{alices_trip['id']}/members/{bobs_friend.id}", headers=alice.headers
    )

    assert response.status_code == 404
    still_member = await client.get(f"{TRIPS}/{bobs_trip['id']}", headers=bobs_friend.headers)
    assert still_member.status_code == 200


# --- T07: 역할을 넘는 요청 ---------------------------------------------------


async def test_viewer_cannot_update_trip(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    viewer = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], viewer, TripRole.VIEWER)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}", json={"version": 1, "title": "몰래"}, headers=viewer.headers
    )

    assert response.status_code == 403
    assert response.json()["code"] == "forbidden"


@pytest.mark.parametrize("role", [TripRole.EDITOR, TripRole.VIEWER])
@pytest.mark.parametrize(
    "action",
    ["delete_trip", "change_role", "remove_other", "transfer"],
)
async def test_editor_cannot_owner_actions(
    client: AsyncClient, db: AsyncSession, role: TripRole, action: str
) -> None:
    owner = await create_user(db)
    actor = await create_user(db)
    other = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], actor, role)
    await add_member(db, trip["id"], other, TripRole.VIEWER)
    base = f"{TRIPS}/{trip['id']}"

    requests = {
        "delete_trip": ("DELETE", f"{base}?version=1", None),
        "change_role": ("PATCH", f"{base}/members/{other.id}", {"role": "editor"}),
        "remove_other": ("DELETE", f"{base}/members/{other.id}", None),
        "transfer": ("POST", f"{base}/transfer-ownership", {"user_id": str(actor.id)}),
    }
    method, url, body = requests[action]

    response = await client.request(method, url, json=body, headers=actor.headers)

    assert response.status_code == 403
    snapshot = (await client.get(base, headers=owner.headers)).json()
    assert {m["user_id"]: m["role"] for m in snapshot["members"]} == {
        str(owner.id): "owner",
        str(actor.id): role.value,
        str(other.id): "viewer",
    }


async def test_member_cannot_remove_other_member(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    editor = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], editor, TripRole.EDITOR)

    # editor가 owner를 내보내려는 시도
    response = await client.delete(
        f"{TRIPS}/{trip['id']}/members/{owner.id}", headers=editor.headers
    )

    assert response.status_code == 403
    assert await _owner_count(db, trip["id"]) == 1


@pytest.mark.parametrize(
    ("method", "path", "body"),
    [
        ("POST", "", {"role": "viewer"}),
        ("POST", "", {"owner_id": "00000000-0000-0000-0000-000000000000"}),
        ("POST", "", {"id": "00000000-0000-0000-0000-000000000000"}),
        ("PATCH", "/{trip_id}", {"version": 1, "title": "x", "my_role": "owner"}),
        ("PATCH", "/{trip_id}", {"version": 1, "title": "x", "member_count": 0}),
        ("PATCH", "/{trip_id}/members/{user_id}", {"role": "viewer", "trip_id": "x"}),
        ("POST", "/{trip_id}/transfer-ownership", {"user_id": "{user_id}", "keep_owner": True}),
    ],
)
async def test_trip_create_with_extra_fields_returns_422(
    client: AsyncClient, db: AsyncSession, method: str, path: str, body: dict[str, Any]
) -> None:
    owner = await create_user(db)
    editor = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], editor, TripRole.EDITOR)
    filled = {
        k: _fill(v, trip["id"], editor.id) if isinstance(v, str) else v for k, v in body.items()
    }
    if path == "":  # 여행 만들기는 정상 본문에 필드를 더한다
        filled = {**TRIP_BODY, **filled}

    response = await client.request(
        method, TRIPS + _fill(path, trip["id"], editor.id), json=filled, headers=owner.headers
    )

    assert response.status_code == 422
    assert response.json()["code"] == "validation_error"


async def test_change_role_to_owner_returns_422(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    editor = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], editor, TripRole.EDITOR)

    response = await client.patch(
        f"{TRIPS}/{trip['id']}/members/{editor.id}", json={"role": "owner"}, headers=owner.headers
    )

    assert response.status_code == 422
    assert await _owner_count(db, trip["id"]) == 1


# --- T08: 내보낸·나간 멤버 ---------------------------------------------------


async def test_removed_member_gets_404(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    member = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], member, TripRole.EDITOR)
    assert (await client.get(f"{TRIPS}/{trip['id']}", headers=member.headers)).status_code == 200

    await client.delete(f"{TRIPS}/{trip['id']}/members/{member.id}", headers=owner.headers)

    get = await client.get(f"{TRIPS}/{trip['id']}", headers=member.headers)
    patch = await client.patch(
        f"{TRIPS}/{trip['id']}", json={"version": 1, "title": "복수"}, headers=member.headers
    )
    assert get.status_code == 404
    assert patch.status_code == 404
    assert (await client.get(TRIPS, headers=member.headers)).json()["items"] == []


async def test_left_member_gets_404(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    viewer = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], viewer, TripRole.VIEWER)

    await client.delete(f"{TRIPS}/{trip['id']}/members/{viewer.id}", headers=viewer.headers)

    assert (await client.get(f"{TRIPS}/{trip['id']}", headers=viewer.headers)).status_code == 404


async def test_former_owner_loses_owner_actions(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    editor = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], editor, TripRole.EDITOR)
    base = f"{TRIPS}/{trip['id']}"
    await client.post(
        f"{base}/transfer-ownership", json={"user_id": str(editor.id)}, headers=owner.headers
    )

    delete = await client.delete(f"{base}?version=1", headers=owner.headers)
    take_back = await client.post(
        f"{base}/transfer-ownership", json={"user_id": str(owner.id)}, headers=owner.headers
    )
    kick = await client.delete(f"{base}/members/{editor.id}", headers=owner.headers)

    assert delete.status_code == take_back.status_code == kick.status_code == 403
    assert await _owner_count(db, trip["id"]) == 1


# --- T29: 동시 수정, owner 1명 -----------------------------------------------


async def test_update_trip_with_stale_version_returns_409(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    editor = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], editor, TripRole.EDITOR)
    base = f"{TRIPS}/{trip['id']}"
    first = await client.patch(base, json={"version": 1, "title": "먼저"}, headers=owner.headers)
    assert first.status_code == 200

    late = await client.patch(base, json={"version": 1, "title": "나중"}, headers=editor.headers)

    assert late.status_code == 409
    body = late.json()
    assert body["code"] == "version_conflict"
    assert body["current"]["title"] == "먼저"
    assert body["current"]["version"] == 2
    assert body["current"]["my_role"] == "editor"
    snapshot = (await client.get(base, headers=owner.headers)).json()
    assert snapshot["trip"]["title"] == "먼저"


async def test_concurrent_updates_with_same_version_one_wins(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    base = f"{TRIPS}/{trip['id']}"

    responses = await asyncio.gather(
        *(
            client.patch(base, json={"version": 1, "title": f"동시 {i}"}, headers=owner.headers)
            for i in range(5)
        )
    )

    assert sorted(r.status_code for r in responses) == [200, 409, 409, 409, 409]
    snapshot = (await client.get(base, headers=owner.headers)).json()
    assert snapshot["trip"]["version"] == 2


async def test_second_owner_rejected_by_db(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    other = await create_user(db)
    trip = await create_trip(client, owner)

    db.add(TripMember(trip_id=uuid.UUID(trip["id"]), user_id=other.id, role=TripRole.OWNER))
    with pytest.raises(IntegrityError):
        await db.commit()
    await db.rollback()


async def test_concurrent_transfers_keep_single_owner(
    client: AsyncClient, db: AsyncSession, migrated_database_url: str
) -> None:
    """다른 트랜잭션이 소유권을 넘기는 중이면, 그 결과를 본 뒤에 처리한다.

    요청 두 개를 동시에 보내는 방식은 테스트 안에서 순서대로 처리돼 버려 경쟁이
    재현되지 않는다. 그래서 테스트가 직접 여행 행을 잠근 채 소유권을 넘기는 중인
    상황을 만들고, 그 사이에 API 요청을 보낸다.
    """
    owner = await create_user(db)
    first = await create_user(db)
    second = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], first, TripRole.EDITOR)
    await add_member(db, trip["id"], second, TripRole.EDITOR)
    trip_id = uuid.UUID(trip["id"])
    url = f"{TRIPS}/{trip['id']}/transfer-ownership"

    engine = create_async_engine(migrated_database_url)
    try:
        async with engine.connect() as conn:
            transaction = await conn.begin()
            # 다른 요청이 owner → first 넘기기를 진행 중인 상황 (여행 행 잠금)
            await conn.execute(
                text("SELECT id FROM trips WHERE id = :id FOR UPDATE"), {"id": trip_id}
            )
            request = asyncio.create_task(
                client.post(url, json={"user_id": str(second.id)}, headers=owner.headers)
            )
            await asyncio.sleep(0.5)
            assert not request.done(), "여행 행 잠금을 기다리지 않고 처리됐다"

            for user_id, role in ((owner.id, "editor"), (first.id, "owner")):
                await conn.execute(
                    text(
                        "UPDATE trip_members SET role = :role "
                        "WHERE trip_id = :trip_id AND user_id = :user_id"
                    ),
                    {"role": role, "trip_id": trip_id, "user_id": user_id},
                )
            await transaction.commit()

        response = await asyncio.wait_for(request, timeout=5)
    finally:
        await engine.dispose()

    # 잠금이 풀린 뒤 다시 읽은 역할은 editor라서 거절된다
    assert response.status_code == 403
    assert await _owner_count(db, trip["id"]) == 1
    owner_row = await db.scalar(
        select(TripMember.user_id).where(
            TripMember.trip_id == trip_id, TripMember.role == TripRole.OWNER
        )
    )
    assert owner_row == first.id


# --- 정보 노출 ---------------------------------------------------------------


async def test_snapshot_members_exclude_email(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    viewer = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], viewer, TripRole.VIEWER)

    response = await client.get(f"{TRIPS}/{trip['id']}", headers=viewer.headers)

    assert "email" not in response.text
    assert "@example.com" not in response.text


@pytest.mark.parametrize("path", ["/api/v1/health", "/api/v1/trips", "/api/v1/no-such-path"])
async def test_responses_have_no_store(client: AsyncClient, db: AsyncSession, path: str) -> None:
    user = await create_user(db)

    response = await client.get(path, headers=user.headers)

    assert response.headers["cache-control"] == "no-store"
