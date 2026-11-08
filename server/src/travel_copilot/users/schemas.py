"""내 정보 API 스키마."""

import uuid

from pydantic import BaseModel

from travel_copilot.auth.schemas import DisplayName
from travel_copilot.core.schemas import RequestModel


class MeRead(BaseModel):
    """내 정보."""

    id: uuid.UUID
    display_name: str
    email: str | None


class MeUpdate(RequestModel):
    """내 정보 수정."""

    display_name: DisplayName
