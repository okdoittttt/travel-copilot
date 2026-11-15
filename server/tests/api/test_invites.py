"""초대 API (features/invites.md 6절)."""

import uuid
from datetime import UTC, datetime, timedelta

from httpx import AsyncClient
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import add_member, create_invite, create_trip, create_user
from travel_copilot.invites.models import Invite
from travel_copilot.jobs.expire_locations import purge_invites
from travel_copilot.trips.models import TripMember, TripRole

PREVIEW = "/api/v1/invites/preview"
ACCEPT = "/api/v1/invites/accept"


def _invites(trip_id: str) -> str:
    return f"/api/v1/trips/{trip_id}/invites"


async def _set(db: AsyncSession, invite_id: str, **values: object) -> None:
    await db.execute(update(Invite).where(Invite.id == uuid.UUID(invite_id)).values(**values))
    await db.commit()


# --- 만들기 ------------------------------------------------------------------


async def test_create_invite_defaults(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db, "홍길동")
    trip = await create_trip(client, owner)

    response = await client.post(_invites(trip["id"]), headers=owner.headers)

    assert response.status_code == 201
    body = response.json()
    assert body["role"] == "viewer"
    assert (body["max_uses"], body["use_count"]) == (10, 0)
    assert body["status"] == "active"
    assert body["created_by_name"] == "홍길동"
    assert body["url"].startswith("https://localhost/invite#")
    expires = datetime.fromisoformat(body["expires_at"])
    assert timedelta(days=2, hours=23) < expires - datetime.now(UTC) <= timedelta(days=3)


async def test_create_invite_with_options(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    body = await create_invite(
        client, owner, trip["id"], role="editor", max_uses=1, expires_in_days=7
    )

    assert (body["role"], body["max_uses"]) == ("editor", 1)


async def test_create_invite_ranges(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    for bad in (
        {"max_uses": 0},
        {"max_uses": 21},
        {"expires_in_days": 0},
        {"expires_in_days": 8},
        {"role": "admin"},
    ):
        response = await client.post(_invites(trip["id"]), json=bad, headers=owner.headers)
        assert response.status_code == 422, bad


async def test_open_invite_limit(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    created = [await create_invite(client, owner, trip["id"]) for _ in range(5)]

    response = await client.post(_invites(trip["id"]), headers=owner.headers)

    assert response.status_code == 409
    assert response.json()["code"] == "invite_limit"
    # 하나를 폐기하면 다시 만들 수 있다 (끝난 링크는 세지 않는다)
    await client.delete(f"{_invites(trip['id'])}/{created[0]['id']}", headers=owner.headers)
    assert (await client.post(_invites(trip["id"]), headers=owner.headers)).status_code == 201


# --- 목록·폐기 ----------------------------------------------------------------


async def test_list_invites_has_no_token(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    first = await create_invite(client, owner, trip["id"])
    second = await create_invite(client, owner, trip["id"], role="editor")

    response = await client.get(_invites(trip["id"]), headers=owner.headers)

    assert response.status_code == 200
    items = response.json()["items"]
    assert [i["id"] for i in items] == [second["id"], first["id"]]
    assert all("url" not in i and "token" not in i for i in items)
    assert first["token"] not in response.text


async def test_list_hides_invites_expired_over_30_days(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    old = await create_invite(client, owner, trip["id"])
    recent = await create_invite(client, owner, trip["id"])
    now = datetime.now(UTC)
    await _set(db, old["id"], expires_at=now - timedelta(days=31))
    await _set(db, recent["id"], expires_at=now - timedelta(days=1))

    items = (await client.get(_invites(trip["id"]), headers=owner.headers)).json()["items"]

    assert [(i["id"], i["status"]) for i in items] == [(recent["id"], "expired")]


async def test_revoke_invite_is_idempotent(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"])
    url = f"{_invites(trip['id'])}/{invite['id']}"

    assert (await client.delete(url, headers=owner.headers)).status_code == 204
    assert (await client.delete(url, headers=owner.headers)).status_code == 204
    items = (await client.get(_invites(trip["id"]), headers=owner.headers)).json()["items"]
    assert items[0]["status"] == "revoked"


async def test_revoke_invite_of_other_trip_returns_404(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    mine = await create_trip(client, owner)
    other_owner = await create_user(db)
    other = await create_trip(client, other_owner)
    invite = await create_invite(client, other_owner, other["id"])

    response = await client.delete(f"{_invites(mine['id'])}/{invite['id']}", headers=owner.headers)

    assert response.status_code == 404
    status = await db.scalar(select(Invite.revoked_at).where(Invite.id == uuid.UUID(invite["id"])))
    assert status is None


async def test_revoke_all_revokes_only_open(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    for _ in range(2):
        await create_invite(client, owner, trip["id"])
    expired = await create_invite(client, owner, trip["id"])
    await _set(db, expired["id"], expires_at=datetime.now(UTC) - timedelta(hours=1))

    response = await client.post(f"{_invites(trip['id'])}/revoke-all", headers=owner.headers)

    assert response.status_code == 200
    assert response.json() == {"revoked": 2}
    items = (await client.get(_invites(trip["id"]), headers=owner.headers)).json()["items"]
    assert sorted(i["status"] for i in items) == ["expired", "revoked", "revoked"]


# --- 미리보기·참여 ------------------------------------------------------------


async def test_preview_shows_minimal_info(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db, "홍길동")
    guest = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"])

    response = await client.post(PREVIEW, json={"token": invite["token"]}, headers=guest.headers)

    assert response.status_code == 200
    assert response.json() == {
        "trip_title": "파리 가족여행",
        "start_date": "2026-12-20",
        "end_date": "2026-12-27",
        "inviter_name": "홍길동",
        "role": "viewer",
        "already_member": False,
        "trip_id": None,
    }
    # 미리보기는 사용 횟수를 쓰지 않는다
    assert await db.scalar(select(Invite.use_count)) == 0


async def test_preview_for_member_returns_trip_id(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"])
    await client.delete(f"{_invites(trip['id'])}/{invite['id']}", headers=owner.headers)

    # 이미 멤버면 끝난 링크여도 바로 이동할 수 있게 trip_id를 준다
    response = await client.post(PREVIEW, json={"token": invite["token"]}, headers=owner.headers)

    assert response.status_code == 200
    assert response.json()["already_member"] is True
    assert response.json()["trip_id"] == trip["id"]


async def test_preview_inviter_null_when_creator_deleted(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    guest = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"])
    await _set(db, invite["id"], created_by=None)

    response = await client.post(PREVIEW, json={"token": invite["token"]}, headers=guest.headers)

    assert response.json()["inviter_name"] is None


async def test_accept_adds_member_with_invite_role(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    guest = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"], role="editor")

    response = await client.post(ACCEPT, json={"token": invite["token"]}, headers=guest.headers)

    assert response.status_code == 200
    assert response.json() == {"trip_id": trip["id"]}
    role = await db.scalar(
        select(TripMember.role).where(
            TripMember.trip_id == uuid.UUID(trip["id"]), TripMember.user_id == guest.id
        )
    )
    assert role is TripRole.EDITOR
    assert await db.scalar(select(Invite.use_count)) == 1
    # 참여한 사람의 여행 목록에 보인다
    trips = (await client.get("/api/v1/trips", headers=guest.headers)).json()["items"]
    assert [t["id"] for t in trips] == [trip["id"]]


async def test_accept_when_already_member_does_not_use_invite(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    member = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], member, TripRole.VIEWER)
    invite = await create_invite(client, owner, trip["id"], role="editor")

    response = await client.post(ACCEPT, json={"token": invite["token"]}, headers=member.headers)

    assert response.status_code == 409
    assert response.json()["code"] == "already_member"
    assert await db.scalar(select(Invite.use_count)) == 0
    # 역할이 링크 역할로 바뀌지 않는다
    role = await db.scalar(select(TripMember.role).where(TripMember.user_id == member.id))
    assert role is TripRole.VIEWER


async def test_unknown_token_returns_404(client: AsyncClient, db: AsyncSession) -> None:
    guest = await create_user(db)

    for path in (PREVIEW, ACCEPT):
        for token in ("A" * 43, "not-a-token"):
            response = await client.post(path, json={"token": token}, headers=guest.headers)
            assert response.status_code == 404
            assert response.json()["code"] == "not_found"


async def test_member_limit(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    for _ in range(19):
        await add_member(db, trip["id"], await create_user(db), TripRole.VIEWER)
    invite = await create_invite(client, owner, trip["id"])
    guest = await create_user(db)

    response = await client.post(ACCEPT, json={"token": invite["token"]}, headers=guest.headers)

    assert response.status_code == 409
    assert response.json()["code"] == "trip_member_limit"
    assert await db.scalar(select(Invite.use_count)) == 0


async def test_invites_deleted_with_trip(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    await create_invite(client, owner, trip["id"])

    await client.delete(f"/api/v1/trips/{trip['id']}?version=1", headers=owner.headers)

    assert await db.scalar(select(func.count()).select_from(Invite)) == 0


async def test_purge_removes_invites_expired_over_30_days(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    old = await create_invite(client, owner, trip["id"])
    await create_invite(client, owner, trip["id"])
    await _set(db, old["id"], expires_at=datetime.now(UTC) - timedelta(days=31))

    assert await purge_invites(db) == 1
    assert await db.scalar(select(func.count()).select_from(Invite)) == 1
