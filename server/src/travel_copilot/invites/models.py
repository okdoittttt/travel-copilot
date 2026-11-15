"""초대 링크 테이블."""

import uuid
from datetime import datetime
from enum import StrEnum

from sqlalchemy import CheckConstraint, DateTime, Enum, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from travel_copilot.core.db import Base
from travel_copilot.core.models import UUIDPrimaryKey


class InviteRole(StrEnum):
    """초대로 받을 수 있는 역할. owner는 타입에서부터 뺀다 (소유권 넘기기로만)."""

    EDITOR = "editor"
    VIEWER = "viewer"


class Invite(UUIDPrimaryKey, Base):
    """초대 링크. 토큰 원문은 저장하지 않고 SHA-256 해시만 둔다 (T10·T14)."""

    __tablename__ = "invites"
    __table_args__ = (
        CheckConstraint("max_uses BETWEEN 1 AND 20", name="max_uses_range"),
        # 원자적 증가(features/invites.md 5.3)가 깨졌을 때의 마지막 방어선 (T12)
        CheckConstraint("use_count >= 0 AND use_count <= max_uses", name="use_count_range"),
    )

    trip_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), nullable=False, index=True
    )
    token_hash: Mapped[str] = mapped_column(String(64), nullable=False, unique=True)
    role: Mapped[InviteRole] = mapped_column(
        Enum(InviteRole, name="invite_role", values_callable=lambda e: [m.value for m in e]),
        nullable=False,
    )
    max_uses: Mapped[int] = mapped_column(Integer, nullable=False)
    use_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
