"""인증 API."""

from typing import Annotated

from fastapi import APIRouter, Depends, Response, status

from travel_copilot.auth.dependencies import CurrentUser, auth_rate_limit, get_auth_service
from travel_copilot.auth.schemas import (
    GoogleLoginRequest,
    LoginResponse,
    LogoutRequest,
    NonceRead,
    RefreshRequest,
    TokenResponse,
    UserSummary,
)
from travel_copilot.auth.service import AuthService, IssuedTokens

router = APIRouter(prefix="/auth", tags=["auth"], dependencies=[Depends(auth_rate_limit)])

Service = Annotated[AuthService, Depends(get_auth_service)]


def _token_response(tokens: IssuedTokens) -> TokenResponse:
    return TokenResponse(
        access_token=tokens.access_token,
        expires_in=tokens.expires_in,
        refresh_token=tokens.refresh_token,
        user=UserSummary(id=tokens.user.id, display_name=tokens.user.display_name),
    )


@router.post("/nonce")
async def issue_nonce(service: Service) -> NonceRead:
    """로그인에 쓸 nonce를 발급한다. 5분 동안 한 번만 쓸 수 있다."""
    issued = await service.issue_nonce()
    return NonceRead(nonce=issued.nonce, expires_in=issued.expires_in)


@router.post("/google/login")
async def login_with_google(body: GoogleLoginRequest, service: Service) -> LoginResponse:
    """Google ID 토큰으로 로그인한다. 처음이면 가입된다."""
    tokens = await service.login_with_google(body.id_token, body.display_name)
    return LoginResponse(**_token_response(tokens).model_dump(), is_new_user=tokens.is_new_user)


@router.post("/refresh")
async def refresh(body: RefreshRequest, service: Service) -> TokenResponse:
    """리프레시 토큰으로 새 토큰을 발급한다. 리프레시 토큰은 매번 바뀐다."""
    return _token_response(await service.refresh(body.refresh_token))


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(body: LogoutRequest, user: CurrentUser, service: Service) -> Response:
    """리프레시 토큰을 폐기한다."""
    await service.logout(user.id, body.refresh_token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
