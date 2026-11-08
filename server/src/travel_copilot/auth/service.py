"""로그인, 토큰 갱신, 로그아웃."""

import logging
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.auth import repository
from travel_copilot.auth.access_token import create_access_token
from travel_copilot.auth.errors import NonceInvalid, TokenInvalid
from travel_copilot.auth.google import GoogleIdentity, GoogleIdTokenVerifier
from travel_copilot.auth.models import AuthProvider
from travel_copilot.core.config import Settings
from travel_copilot.core.tokens import generate_token, hash_token
from travel_copilot.users import repository as users_repository
from travel_copilot.users.models import User

logger = logging.getLogger(__name__)

NONCE_TTL_SECONDS = 300
DEFAULT_DISPLAY_NAME = "여행자"
MAX_DISPLAY_NAME_LENGTH = 50


@dataclass(frozen=True)
class IssuedNonce:
    """발급한 nonce."""

    nonce: str
    expires_in: int


@dataclass(frozen=True)
class IssuedTokens:
    """로그인·갱신 결과."""

    access_token: str
    refresh_token: str
    expires_in: int
    user: User
    is_new_user: bool = False


class AuthService:
    """소셜 로그인과 자체 토큰의 발급·갱신·폐기.

    공급자별로 다른 건 ID 토큰 검증뿐이다. 토큰 발급·갱신·폐기는 공급자와 무관하게
    동작해서, 카카오·Apple(F10)은 검증 부분만 추가하면 된다.
    """

    def __init__(
        self, session: AsyncSession, settings: Settings, google: GoogleIdTokenVerifier
    ) -> None:
        """서비스를 만든다.

        Args:
            session: 요청 단위 DB 세션.
            settings: 토큰 수명·서명 키가 들어 있는 설정.
            google: Google ID 토큰 검증기.
        """
        self._session = session
        self._settings = settings
        self._google = google

    async def issue_nonce(self) -> IssuedNonce:
        """로그인용 nonce를 발급한다.

        원문은 앱에 주고 DB에는 해시만 저장한다. 발급할 때 만료된 nonce를 함께 지운다.

        Returns:
            nonce 원문과 유효 시간.
        """
        now = datetime.now(UTC)
        nonce = generate_token()
        await repository.delete_expired_nonces(self._session, now)
        await repository.add_nonce(
            self._session, hash_token(nonce), now + timedelta(seconds=NONCE_TTL_SECONDS)
        )
        await self._session.commit()
        return IssuedNonce(nonce=nonce, expires_in=NONCE_TTL_SECONDS)

    async def login_with_google(self, id_token: str, display_name: str | None) -> IssuedTokens:
        """Google ID 토큰으로 로그인한다. 처음 보는 계정이면 가입시킨다.

        순서: ID 토큰 검증 → 토큰 안 nonce를 한 번 쓰고 지움 → (provider, sub)로 사용자
        조회·생성 → 자체 토큰 발급. 이메일로는 사용자를 찾지 않는다 (T02).

        Args:
            id_token: 앱이 Google에서 받은 ID 토큰.
            display_name: 처음 가입할 때 쓸 표시 이름. 없으면 Google 이름.

        Returns:
            발급한 토큰과 사용자.

        Raises:
            IdTokenInvalid: ID 토큰 검증에 실패했을 때.
            NonceInvalid: nonce가 발급되지 않았거나 만료·사용됐을 때.
            UpstreamError: Google 공개키를 받지 못했을 때.
        """
        identity = await self._google.verify(id_token)
        now = datetime.now(UTC)
        if not await repository.consume_nonce(self._session, hash_token(identity.nonce), now):
            # nonce 사용 실패도 커밋해야 할 변경이 없으므로 롤백만 한다
            await self._session.rollback()
            raise NonceInvalid

        user, is_new = await self._find_or_create_user(identity, display_name)
        tokens = await self._issue_tokens(user, family_id=uuid.uuid4(), now=now)
        await self._session.commit()
        return IssuedTokens(
            access_token=tokens.access_token,
            refresh_token=tokens.refresh_token,
            expires_in=tokens.expires_in,
            user=user,
            is_new_user=is_new,
        )

    async def refresh(self, refresh_token: str) -> IssuedTokens:
        """리프레시 토큰을 새 토큰으로 교체한다.

        이미 쓴 토큰이 다시 오면 탈취로 보고 그 묶음 전체를 폐기한다 (T03).

        Args:
            refresh_token: 앱이 가진 리프레시 토큰 원문.

        Returns:
            새 액세스·리프레시 토큰.

        Raises:
            TokenInvalid: 없거나, 이미 썼거나, 폐기·만료된 토큰일 때.
        """
        now = datetime.now(UTC)
        token_hash = hash_token(refresh_token)
        current = await repository.mark_refresh_token_used(self._session, token_hash, now)
        if current is None:
            existing = await repository.find_refresh_token(self._session, token_hash)
            if existing is not None and existing.used_at is not None:
                await repository.revoke_family(self._session, existing.family_id, now)
                await self._session.commit()
                logger.warning(
                    "리프레시 토큰 재사용 감지, 묶음 폐기",
                    extra={"user_id": str(existing.user_id), "family_id": str(existing.family_id)},
                )
            else:
                await self._session.rollback()
            raise TokenInvalid

        user = await users_repository.get_by_id(self._session, current.user_id)
        if user is None:
            await self._session.rollback()
            raise TokenInvalid
        tokens = await self._issue_tokens(user, family_id=current.family_id, now=now)
        await self._session.commit()
        return tokens

    async def logout(self, user_id: uuid.UUID, refresh_token: str) -> None:
        """리프레시 토큰이 속한 묶음을 폐기한다.

        다른 사용자의 토큰이거나 없는 토큰이면 아무것도 하지 않는다 (결과를 알려주지 않음).

        Args:
            user_id: 로그아웃하는 사용자.
            refresh_token: 앱이 가진 리프레시 토큰 원문.
        """
        existing = await repository.find_refresh_token(self._session, hash_token(refresh_token))
        if existing is not None and existing.user_id == user_id:
            await repository.revoke_family(self._session, existing.family_id, datetime.now(UTC))
            await self._session.commit()

    async def _find_or_create_user(
        self, identity: GoogleIdentity, display_name: str | None
    ) -> tuple[User, bool]:
        user_id = await repository.find_user_id_by_social(
            self._session, AuthProvider.GOOGLE, identity.subject
        )
        if user_id is not None:
            user = await users_repository.get_by_id(self._session, user_id)
            if user is not None:
                return user, False

        name = (display_name or identity.name or DEFAULT_DISPLAY_NAME).strip()
        name = name[:MAX_DISPLAY_NAME_LENGTH] or DEFAULT_DISPLAY_NAME
        try:
            async with self._session.begin_nested():
                user = await users_repository.create(self._session, name, identity.email)
                await repository.create_social_account(
                    self._session, user.id, AuthProvider.GOOGLE, identity.subject
                )
        except IntegrityError:
            # 같은 계정이 동시에 처음 로그인한 경우: 먼저 만들어진 사용자를 쓴다
            existing_id = await repository.find_user_id_by_social(
                self._session, AuthProvider.GOOGLE, identity.subject
            )
            existing = (
                await users_repository.get_by_id(self._session, existing_id)
                if existing_id
                else None
            )
            if existing is None:
                raise
            return existing, False
        return user, True

    async def _issue_tokens(self, user: User, family_id: uuid.UUID, now: datetime) -> IssuedTokens:
        refresh_token = generate_token()
        await repository.add_refresh_token(
            self._session,
            user_id=user.id,
            family_id=family_id,
            token_hash=hash_token(refresh_token),
            expires_at=now + timedelta(days=self._settings.refresh_token_ttl_days),
        )
        access_token = create_access_token(
            user.id,
            self._settings.jwt_secret.get_secret_value(),
            self._settings.access_token_ttl_seconds,
        )
        return IssuedTokens(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=self._settings.access_token_ttl_seconds,
            user=user,
        )
