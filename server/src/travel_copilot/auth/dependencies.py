"""인증 관련 FastAPI 의존성."""

from typing import Annotated

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.auth.access_token import decode_access_token
from travel_copilot.auth.errors import TokenInvalid, TokenMissing
from travel_copilot.auth.service import AuthService
from travel_copilot.core.config import Settings
from travel_copilot.core.db import get_session
from travel_copilot.core.rate_limit import limit_by_ip
from travel_copilot.users import repository as users_repository
from travel_copilot.users.models import User

# auto_error=False: 헤더가 없을 때 FastAPI 기본 403 대신 우리 401 형식으로 응답하기 위해
_bearer = HTTPBearer(auto_error=False)


def get_settings(request: Request) -> Settings:
    """앱에 등록된 설정을 꺼낸다.

    Args:
        request: 현재 요청.

    Returns:
        앱 생성 시 넣은 설정.
    """
    settings: Settings = request.app.state.settings
    return settings


def get_auth_service(
    request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> AuthService:
    """요청 단위 인증 서비스를 만든다.

    Args:
        request: 현재 요청 (Google 검증기를 꺼내는 데 사용).
        session: 요청 단위 DB 세션.
        settings: 서버 설정.

    Returns:
        인증 서비스.
    """
    return AuthService(session, settings, request.app.state.google_verifier)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> User:
    """액세스 토큰으로 요청한 사용자를 찾는다.

    토큰 검증 후 사용자 행을 매번 읽는다. 그래서 삭제된 사용자는 토큰이 남아 있어도
    즉시 거절된다 (T04).

    Args:
        credentials: Authorization 헤더의 Bearer 토큰.
        session: 요청 단위 DB 세션.
        settings: 서명 키가 들어 있는 설정.

    Returns:
        요청한 사용자.

    Raises:
        TokenMissing: 헤더가 없거나 Bearer가 아닐 때.
        TokenExpired: 토큰이 만료됐을 때.
        TokenInvalid: 토큰이 잘못됐거나 사용자가 없을 때.
    """
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise TokenMissing
    user_id = decode_access_token(credentials.credentials, settings.jwt_secret.get_secret_value())
    user = await users_repository.get_by_id(session, user_id)
    if user is None:
        raise TokenInvalid
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]

auth_rate_limit = limit_by_ip(
    "auth", lambda request: get_settings(request).auth_rate_limit_per_minute
)
