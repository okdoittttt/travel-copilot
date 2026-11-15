"""초대 API 요청·응답 스키마."""

import uuid
from datetime import date, datetime
from enum import StrEnum

from pydantic import BaseModel, Field

from travel_copilot.core.schemas import RequestModel
from travel_copilot.invites.models import InviteRole

MAX_USES_DEFAULT = 10
MAX_USES_LIMIT = 20
EXPIRES_DAYS_DEFAULT = 3
EXPIRES_DAYS_LIMIT = 7


class InviteStatus(StrEnum):
    """링크 상태. 서버가 계산해서 내려준다."""

    ACTIVE = "active"
    EXPIRED = "expired"
    REVOKED = "revoked"
    EXHAUSTED = "exhausted"


class InviteCreate(RequestModel):
    """링크 만들기 요청. 모두 생략하면 보기 전용·10회·3일."""

    role: InviteRole = InviteRole.VIEWER
    max_uses: int = Field(default=MAX_USES_DEFAULT, ge=1, le=MAX_USES_LIMIT)
    expires_in_days: int = Field(default=EXPIRES_DAYS_DEFAULT, ge=1, le=EXPIRES_DAYS_LIMIT)


class InviteRead(BaseModel):
    """링크 목록 항목. 토큰은 담지 않는다."""

    id: uuid.UUID
    role: InviteRole
    max_uses: int
    use_count: int
    expires_at: datetime
    revoked_at: datetime | None
    created_at: datetime
    created_by_name: str | None
    status: InviteStatus


class InviteCreated(InviteRead):
    """만들기 응답. 토큰이 담긴 `url`은 이 응답에서만 나온다."""

    url: str


class InviteList(BaseModel):
    """링크 목록."""

    items: list[InviteRead]


class RevokeAllResult(BaseModel):
    """모든 링크 폐기 결과."""

    revoked: int


class InviteToken(RequestModel):
    """미리보기·참여 요청. 토큰은 본문으로만 받는다 (쿼리 문자열 금지, T11).

    형식 검사는 서비스가 한다. 형식이 틀린 토큰도 없는 토큰과 같은 404로 응답하기 위해서다.
    """

    token: str = Field(min_length=1, max_length=128)


class InvitePreview(BaseModel):
    """참여 확인 화면용 최소 정보 (features/invites.md 5.4, T33)."""

    trip_title: str
    start_date: date
    end_date: date
    inviter_name: str | None
    role: InviteRole
    already_member: bool
    trip_id: uuid.UUID | None


class InviteAccepted(BaseModel):
    """참여 결과."""

    trip_id: uuid.UUID
