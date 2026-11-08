"""인증 API 요청·응답 스키마."""

import uuid
from typing import Annotated, Literal

from pydantic import BaseModel, Field

from travel_copilot.core.schemas import RequestModel

DisplayName = Annotated[str, Field(min_length=1, max_length=50)]
# JWT·토큰 길이 상한. 터무니없이 긴 입력을 검증 전에 거절한다.
IdToken = Annotated[str, Field(min_length=1, max_length=4096)]
OpaqueToken = Annotated[str, Field(min_length=1, max_length=256)]


class NonceRead(BaseModel):
    """nonce 발급 응답."""

    nonce: str
    expires_in: int


class GoogleLoginRequest(RequestModel):
    """Google 로그인 요청. nonce는 ID 토큰 안에 들어 있어 따로 받지 않는다."""

    id_token: IdToken
    display_name: DisplayName | None = None


class RefreshRequest(RequestModel):
    """토큰 갱신 요청."""

    refresh_token: OpaqueToken


class LogoutRequest(RequestModel):
    """로그아웃 요청."""

    refresh_token: OpaqueToken


class UserSummary(BaseModel):
    """토큰 응답에 담는 사용자 정보."""

    id: uuid.UUID
    display_name: str


class TokenResponse(BaseModel):
    """토큰 발급 응답."""

    access_token: str
    token_type: Literal["Bearer"] = "Bearer"  # noqa: S105  # 비밀값이 아니라 토큰 종류 이름
    expires_in: int
    refresh_token: str
    user: UserSummary


class LoginResponse(TokenResponse):
    """로그인 응답."""

    is_new_user: bool
