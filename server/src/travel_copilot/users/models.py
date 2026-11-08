"""사용자 테이블."""

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from travel_copilot.core.db import Base
from travel_copilot.core.models import Timestamps, UUIDPrimaryKey


class User(UUIDPrimaryKey, Timestamps, Base):
    """사용자.

    로그인 식별은 `social_accounts`의 (provider, subject)로만 한다.
    `email`은 표시·연락용이고 계정을 찾는 데 쓰지 않는다 (T02).
    """

    __tablename__ = "users"

    display_name: Mapped[str] = mapped_column(String(50), nullable=False)
    email: Mapped[str | None] = mapped_column(String(320), nullable=True)
