"""일정 항목 테이블."""

import uuid
from datetime import date, datetime, time
from decimal import Decimal
from enum import StrEnum

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Time,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from travel_copilot.core.db import Base
from travel_copilot.core.models import Timestamps, UUIDPrimaryKey


class TravelMode(StrEnum):
    """이전 항목에서 이 항목까지의 이동수단. 사용자가 고른다."""

    DRIVE = "drive"
    TRANSIT = "transit"
    WALK = "walk"


class ItineraryItem(UUIDPrimaryKey, Timestamps, Base):
    """일정 항목.

    제목·메모는 사용자 콘텐츠다. Google에서 받은 것은 `place_id`와 좌표뿐이고,
    좌표는 받은 지 30일이 지나면 지운다 (05-data-model 2절).
    """

    __tablename__ = "itinerary_items"
    __table_args__ = (
        # 순서를 바꾸는 도중 잠깐 겹치는 상태를 허용하려고 트랜잭션 끝에 검사한다 (5.3)
        UniqueConstraint("trip_id", "day", "position", deferrable=True, initially="DEFERRED"),
        CheckConstraint("position >= 0", name="position_non_negative"),
        CheckConstraint("stay_minutes BETWEEN 0 AND 1440", name="stay_minutes_range"),
        CheckConstraint(
            "(lat IS NULL AND lng IS NULL AND location_fetched_at IS NULL)"
            " OR (lat IS NOT NULL AND lng IS NOT NULL AND location_fetched_at IS NOT NULL)",
            name="location_all_or_nothing",
        ),
    )

    trip_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), nullable=False
    )
    day: Mapped[date] = mapped_column(Date, nullable=False)
    position: Mapped[int] = mapped_column(Integer, nullable=False)
    title: Mapped[str] = mapped_column(String(100), nullable=False)
    memo: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    google_place_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    lat: Mapped[Decimal | None] = mapped_column(Numeric(9, 6), nullable=True)
    lng: Mapped[Decimal | None] = mapped_column(Numeric(9, 6), nullable=True)
    # 좌표 정리 명령이 이 컬럼으로 오래된 좌표를 찾는다
    location_fetched_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
    start_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    stay_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    travel_mode: Mapped[TravelMode | None] = mapped_column(
        Enum(TravelMode, name="travel_mode", values_callable=lambda e: [m.value for m in e]),
        nullable=True,
    )
    version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    updated_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
