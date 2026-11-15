"""T10~T14·T33: 초대 링크 보안 (features/invites.md 8절).

방어(원자적 증가, 해시 저장, owner 확인, 요청 제한)를 빼면 이 파일의 테스트가 실패해야 한다.
"""

import asyncio
import hashlib
import json
import logging
import uuid
from collections.abc import Iterator
from datetime import UTC, datetime, timedelta
from pathlib import Path

import pytest
from httpx import AsyncClient
from sqlalchemy import func, select, text, update
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import add_member, create_invite, create_trip, create_user
from travel_copilot.invites.models import Invite
from travel_copilot.trips.models import TripMember, TripRole

PREVIEW = "/api/v1/invites/preview"
ACCEPT = "/api/v1/invites/accept"


def _invites(trip_id: str) -> str:
    return f"/api/v1/trips/{trip_id}/invites"


async def _member_count(db: AsyncSession, trip_id: str) -> int:
    count = await db.scalar(
        select(func.count()).select_from(TripMember).where(TripMember.trip_id == uuid.UUID(trip_id))
    )
    return int(count or 0)


# --- T14: 해시만 저장 ---------------------------------------------------------


async def test_invite_stores_only_hash(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"])
    token = invite["token"]

    row = (await db.execute(text("SELECT * FROM invites"))).mappings().one()

    assert row["token_hash"] == hashlib.sha256(token.encode()).hexdigest()
    assert all(token not in str(value) for value in row.values())


# --- T11: owner만 관리, 역할 규칙 ---------------------------------------------


@pytest.mark.parametrize("role", [TripRole.EDITOR, TripRole.VIEWER])
async def test_non_owner_cannot_manage_invites(
    client: AsyncClient, db: AsyncSession, role: TripRole
) -> None:
    owner = await create_user(db)
    member = await create_user(db)
    trip = await create_trip(client, owner)
    await add_member(db, trip["id"], member, role)
    invite = await create_invite(client, owner, trip["id"])
    base = _invites(trip["id"])

    requests = [
        ("POST", base),
        ("GET", base),
        ("DELETE", f"{base}/{invite['id']}"),
        ("POST", f"{base}/revoke-all"),
    ]
    for method, url in requests:
        response = await client.request(method, url, headers=member.headers)
        assert response.status_code == 403, (method, url)

    status = (await client.get(base, headers=owner.headers)).json()["items"][0]["status"]
    assert status == "active"
    assert await db.scalar(select(func.count()).select_from(Invite)) == 1


async def test_invite_role_rules(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)

    response = await client.post(
        _invites(trip["id"]), json={"role": "owner"}, headers=owner.headers
    )
    assert response.status_code == 422
    extra = await client.post(_invites(trip["id"]), json={"use_count": 5}, headers=owner.headers)
    assert extra.status_code == 422
    default = await create_invite(client, owner, trip["id"])
    assert default["role"] == "viewer"


# --- T11: 끝난 링크 -------------------------------------------------------------


@pytest.mark.parametrize(
    ("state", "code"),
    [
        ("revoked", "invite_revoked"),
        ("expired", "invite_expired"),
        ("exhausted", "invite_exhausted"),
    ],
)
async def test_invite_ended_states(
    client: AsyncClient, db: AsyncSession, state: str, code: str
) -> None:
    owner = await create_user(db)
    guest = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"], max_uses=2)
    states: dict[str, dict[str, object]] = {
        "revoked": {"revoked_at": datetime.now(UTC)},
        "expired": {"expires_at": datetime.now(UTC) - timedelta(seconds=1)},
        "exhausted": {"use_count": 2},
    }
    values = states[state]
    await db.execute(update(Invite).values(**values))
    await db.commit()

    for path in (PREVIEW, ACCEPT):
        response = await client.post(path, json={"token": invite["token"]}, headers=guest.headers)
        assert response.status_code == 410, path
        assert response.json()["code"] == code

    assert await _member_count(db, trip["id"]) == 1


async def test_removed_member_cannot_rejoin_after_revoke_all(
    client: AsyncClient, db: AsyncSession
) -> None:
    owner = await create_user(db)
    guest = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"])
    body = {"token": invite["token"]}
    assert (await client.post(ACCEPT, json=body, headers=guest.headers)).status_code == 200

    await client.delete(f"/api/v1/trips/{trip['id']}/members/{guest.id}", headers=owner.headers)
    # 내보내기만 하면 남은 링크로 다시 들어올 수 있다 (그래서 전체 폐기를 둔다, 5.6)
    await client.post(f"{_invites(trip['id'])}/revoke-all", headers=owner.headers)

    response = await client.post(ACCEPT, json=body, headers=guest.headers)
    assert response.status_code == 410
    assert await _member_count(db, trip["id"]) == 1


# --- T11: 토큰이 남는 곳 --------------------------------------------------------


async def test_invite_token_not_in_query(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    guest = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"])

    for path in (PREVIEW, ACCEPT):
        response = await client.post(f"{path}?token={invite['token']}", headers=guest.headers)
        assert response.status_code == 422
    assert await _member_count(db, trip["id"]) == 1


class _ListHandler(logging.Handler):
    def __init__(self) -> None:
        super().__init__(level=logging.DEBUG)
        self.lines: list[str] = []

    def emit(self, record: logging.LogRecord) -> None:
        self.lines.append(f"{record.name} {record.getMessage()} {record.__dict__}")


@pytest.fixture
def all_logs() -> Iterator[_ListHandler]:
    """모든 로거의 DEBUG 이상 기록을 모은다 (SQL 파라미터 포함)."""
    handler = _ListHandler()
    root = logging.getLogger()
    previous = root.level
    root.addHandler(handler)
    root.setLevel(logging.DEBUG)
    yield handler
    root.removeHandler(handler)
    root.setLevel(previous)


async def test_invite_token_not_logged(
    client: AsyncClient, db: AsyncSession, all_logs: _ListHandler
) -> None:
    owner = await create_user(db)
    guest = await create_user(db)
    trip = await create_trip(client, owner)

    invite = await create_invite(client, owner, trip["id"])
    body = {"token": invite["token"]}
    await client.post(PREVIEW, json=body, headers=guest.headers)
    await client.post(ACCEPT, json=body, headers=guest.headers)
    await client.post(ACCEPT, json=body, headers=guest.headers)  # 409 경로도

    joined = "\n".join(all_logs.lines)
    assert "/api/v1/invites/accept" in joined, "요청 로그가 수집돼야 한다"
    assert invite["token"] not in joined


# --- T10: 요청 횟수 제한 --------------------------------------------------------


async def test_invite_rate_limit(client: AsyncClient, db: AsyncSession) -> None:
    guest = await create_user(db)
    body = {"token": "A" * 43}

    statuses = [
        (await client.post(PREVIEW if i % 2 else ACCEPT, json=body, headers=guest.headers))
        for i in range(11)
    ]

    # 미리보기·참여 합산 분당 10회
    assert [r.status_code for r in statuses[:10]] == [404] * 10
    assert statuses[10].status_code == 429
    assert "Retry-After" in statuses[10].headers


# --- T12: 동시 참여 -----------------------------------------------------------


async def test_concurrent_accept_respects_max_uses(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"], max_uses=1)
    guests = [await create_user(db) for _ in range(5)]

    responses = await asyncio.gather(
        *(client.post(ACCEPT, json={"token": invite["token"]}, headers=g.headers) for g in guests)
    )

    assert sorted(r.status_code for r in responses) == [200, 410, 410, 410, 410]
    assert {r.json()["code"] for r in responses if r.status_code == 410} == {"invite_exhausted"}
    assert await db.scalar(select(Invite.use_count)) == 1
    assert await _member_count(db, trip["id"]) == 2


async def test_concurrent_accept_same_user(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    guest = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"])

    responses = await asyncio.gather(
        *(client.post(ACCEPT, json={"token": invite["token"]}, headers=guest.headers) for _ in "ab")
    )

    assert sorted(r.status_code for r in responses) == [200, 409]
    assert await db.scalar(select(Invite.use_count)) == 1
    assert await _member_count(db, trip["id"]) == 2


async def test_concurrent_accept_member_limit(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    trip = await create_trip(client, owner)
    for _ in range(18):
        await add_member(db, trip["id"], await create_user(db), TripRole.VIEWER)
    invite = await create_invite(client, owner, trip["id"])
    guests = [await create_user(db) for _ in range(2)]

    responses = await asyncio.gather(
        *(client.post(ACCEPT, json={"token": invite["token"]}, headers=g.headers) for g in guests)
    )

    assert sorted(r.status_code for r in responses) == [200, 409]
    assert await _member_count(db, trip["id"]) == 20


# --- T33: 미리보기 정보 ---------------------------------------------------------


async def test_invite_preview_fields(client: AsyncClient, db: AsyncSession) -> None:
    owner = await create_user(db)
    guest = await create_user(db)
    trip = await create_trip(client, owner)
    invite = await create_invite(client, owner, trip["id"])

    body = (
        await client.post(PREVIEW, json={"token": invite["token"]}, headers=guest.headers)
    ).json()

    assert set(body) == {
        "trip_title",
        "start_date",
        "end_date",
        "inviter_name",
        "role",
        "already_member",
        "trip_id",
    }
    assert body["trip_id"] is None


# --- W01·확인 파일 (features/invites.md 5.8) --------------------------------------

WEB_DIR = Path(__file__).resolve().parents[3] / "infra" / "web"


def test_invite_page_has_no_script() -> None:
    """W01은 # 뒤 토큰을 읽거나 보내지 않도록 JavaScript가 없어야 한다."""
    html = (WEB_DIR / "invite.html").read_text().lower()

    assert "<script" not in html
    assert "javascript:" not in html
    assert " on" not in html.split("<body", 1)[1].replace(" one", ""), "인라인 이벤트 핸들러 금지"


def test_app_link_files_are_valid_json() -> None:
    aasa = json.loads((WEB_DIR / "apple-app-site-association").read_text())
    components = aasa["applinks"]["details"][0]["components"]
    assert [c["/"] for c in components] == ["/invite"]
    links = json.loads((WEB_DIR / "assetlinks.json").read_text())
    assert links[0]["target"]["package_name"] == "com.okdoittttt.travelcopilot"
