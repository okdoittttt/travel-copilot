"""로그인 관련 테이블."""

import uuid
from datetime import datetime
from enum import StrEnum

from sqlalchemy import CHAR, DateTime, Enum, ForeignKey, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from travel_copilot.core.db import Base
from travel_copilot.core.models import UUIDPrimaryKey


class AuthProvider(StrEnum):
    """소셜 로그인 공급자. F1은 google만 쓰고 나머지는 F10에서 쓴다."""

    KAKAO = "kakao"
    APPLE = "apple"
    GOOGLE = "google"


class SocialAccount(UUIDPrimaryKey, Base):
    """사용자와 소셜 로그인 계정의 연결."""

    __tablename__ = "social_accounts"
    __table_args__ = (UniqueConstraint("provider", "subject"),)

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    provider: Mapped[AuthProvider] = mapped_column(
        Enum(AuthProvider, name="auth_provider", values_callable=lambda e: [m.value for m in e]),
        nullable=False,
    )
    # 공급자가 준 사용자 ID (ID 토큰의 sub)
    subject: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class RefreshToken(UUIDPrimaryKey, Base):
    """리프레시 토큰. 원문은 저장하지 않고 SHA-256 해시만 둔다 (T03)."""

    __tablename__ = "refresh_tokens"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # 한 번의 로그인에서 교체되며 이어진 토큰 묶음. 재사용이 감지되면 묶음 전체를 폐기한다.
    family_id: Mapped[uuid.UUID] = mapped_column(nullable=False, index=True)
    token_hash: Mapped[str] = mapped_column(CHAR(64), nullable=False, unique=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class AuthNonce(Base):
    """로그인용 nonce. 해시만 저장하고, 로그인 시 한 번 쓰면 지운다."""

    __tablename__ = "auth_nonces"

    nonce_hash: Mapped[str] = mapped_column(CHAR(64), primary_key=True)
    # 만료 nonce 정리(DELETE ... WHERE expires_at <= now)용 인덱스
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
