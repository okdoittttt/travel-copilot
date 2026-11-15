"""초대 토큰·상태 규칙 (features/invites.md 5.1·5.5)."""

import hashlib
import uuid
from datetime import UTC, datetime, timedelta

import pytest
from pydantic import ValidationError

from tests.conftest import make_settings
from travel_copilot.invites import tokens
from travel_copilot.invites.models import Invite, InviteRole
from travel_copilot.invites.schemas import InviteStatus
from travel_copilot.invites.service import invite_status, invite_url

NOW = datetime(2026, 11, 15, 12, 0, tzinfo=UTC)


def _invite(**overrides: object) -> Invite:
    values: dict[str, object] = {
        "trip_id": uuid.uuid4(),
        "token_hash": "0" * 64,
        "role": InviteRole.VIEWER,
        "max_uses": 10,
        "use_count": 0,
        "expires_at": NOW + timedelta(days=1),
        "revoked_at": None,
    }
    values.update(overrides)
    return Invite(**values)


def test_invite_token_entropy() -> None:
    """T10: 43자 URL-safe(256비트), 1,000개 중복 없음."""
    generated = {tokens.new_token() for _ in range(1000)}

    assert len(generated) == 1000
    assert all(len(t) == 43 and tokens.is_well_formed(t) for t in generated)


def test_hash_token_is_sha256_hex() -> None:
    token = tokens.new_token()

    assert tokens.hash_token(token) == hashlib.sha256(token.encode()).hexdigest()
    assert len(tokens.hash_token(token)) == 64


@pytest.mark.parametrize(
    "value", ["", "short", "a" * 42, "a" * 44, "a" * 42 + "=", "a" * 42 + "/", "가" * 43]
)
def test_malformed_tokens_rejected(value: str) -> None:
    assert not tokens.is_well_formed(value)


@pytest.mark.parametrize(
    ("overrides", "expected"),
    [
        ({}, InviteStatus.ACTIVE),
        ({"revoked_at": NOW}, InviteStatus.REVOKED),
        ({"expires_at": NOW}, InviteStatus.EXPIRED),
        ({"use_count": 10}, InviteStatus.EXHAUSTED),
        # 여러 이유가 겹치면 폐기 → 만료 → 소진 순
        ({"revoked_at": NOW, "expires_at": NOW, "use_count": 10}, InviteStatus.REVOKED),
        ({"expires_at": NOW, "use_count": 10}, InviteStatus.EXPIRED),
    ],
)
def test_invite_status(overrides: dict[str, object], expected: InviteStatus) -> None:
    assert invite_status(_invite(**overrides), NOW) is expected


def test_invite_url_puts_token_in_fragment() -> None:
    assert (
        invite_url("https://travel.example.com", "abc") == "https://travel.example.com/invite#abc"
    )


def test_invite_base_url_trailing_slash_removed() -> None:
    assert make_settings(invite_base_url="https://a.example.com/").invite_base_url == (
        "https://a.example.com"
    )


@pytest.mark.parametrize(
    "value", ["http://a.example.com", "https://a.example.com/?x=1", "https://a.example.com/#x"]
)
def test_invite_base_url_must_be_plain_https(value: str) -> None:
    with pytest.raises(ValidationError):
        make_settings(invite_base_url=value)
