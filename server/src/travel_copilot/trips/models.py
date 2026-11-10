"""여행 관련 테이블."""

import uuid
from datetime import date, datetime
from enum import StrEnum

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    String,
    func,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from travel_copilot.core.db import Base
from travel_copilot.core.models import Timestamps, UUIDPrimaryKey


class TripRole(StrEnum):
    """여행 안에서의 역할. 권한표는 05-data-model.md 5절."""

    OWNER = "owner"
    EDITOR = "editor"
    VIEWER = "viewer"

    @property
    def rank(self) -> int:
        """역할 서열. 숫자가 클수록 권한이 많다."""
        return _ROLE_RANK[self]

    def at_least(self, minimum: "TripRole") -> bool:
        """이 역할이 최소 역할 이상인지 확인한다.

        Args:
            minimum: 필요한 최소 역할.

        Returns:
            최소 역할 이상이면 True.
        """
        return self.rank >= minimum.rank


_ROLE_RANK = {TripRole.VIEWER: 1, TripRole.EDITOR: 2, TripRole.OWNER: 3}


class Trip(UUIDPrimaryKey, Timestamps, Base):
    """여행.

    날짜는 여행지 현지 날짜이고, `timezone`(IANA 이름)과 같이 해석한다.
    """

    __tablename__ = "trips"
    __table_args__ = (CheckConstraint("start_date <= end_date", name="period_order"),)

    title: Mapped[str] = mapped_column(String(100), nullable=False)
    destination: Mapped[str] = mapped_column(String(100), nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    timezone: Mapped[str] = mapped_column(String(64), nullable=False)
    # 여행 정보를 고칠 때마다 1씩 늘린다 (동시 수정 감지, T29)
    version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)


class TripMember(Base):
    """여행 멤버와 역할."""

    __tablename__ = "trip_members"
    __table_args__ = (
        # 여행마다 owner는 정확히 1명 (T29)
        Index(
            "uq_trip_members_one_owner",
            "trip_id",
            unique=True,
            postgresql_where=text("role = 'owner'"),
        ),
    )

    trip_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), primary_key=True
    )
    # 내 여행 목록 조회용 인덱스
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True, index=True
    )
    role: Mapped[TripRole] = mapped_column(
        Enum(TripRole, name="trip_role", values_callable=lambda e: [m.value for m in e]),
        nullable=False,
    )
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
