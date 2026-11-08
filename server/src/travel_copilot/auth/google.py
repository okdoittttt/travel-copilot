"""Google ID 토큰 검증."""

import asyncio
import logging
import re
import time
from dataclasses import dataclass
from typing import Any

import httpx
import jwt

from travel_copilot.auth.errors import IdTokenInvalid
from travel_copilot.core.errors import UpstreamError

logger = logging.getLogger(__name__)

GOOGLE_JWKS_URL = "https://www.googleapis.com/oauth2/v3/certs"
GOOGLE_ISSUERS = frozenset({"https://accounts.google.com", "accounts.google.com"})
# 기기와 서버의 시계 오차 허용 범위
CLOCK_SKEW_SECONDS = 60
# Cache-Control이 없을 때 공개키를 캐시할 시간
DEFAULT_JWKS_TTL_SECONDS = 3600
_MAX_AGE = re.compile(r"max-age=(\d+)")


@dataclass(frozen=True)
class GoogleIdentity:
    """검증을 통과한 Google ID 토큰에서 꺼낸 값."""

    subject: str
    nonce: str
    email: str | None
    name: str | None


class GoogleJwksCache:
    """Google 공개키(JWKS)를 받아서 캐시한다.

    Google은 공개키를 주기적으로 바꾼다. 응답의 `Cache-Control: max-age` 동안 캐시하고,
    모르는 kid가 오면 한 번 다시 받는다 (키 교체 직후 대응).
    """

    def __init__(self, http: httpx.AsyncClient, url: str = GOOGLE_JWKS_URL) -> None:
        """캐시를 만든다.

        Args:
            http: 공개키를 받을 HTTP 클라이언트 (타임아웃이 설정된 것).
            url: JWKS 주소.
        """
        self._http = http
        self._url = url
        self._keys: dict[str, jwt.PyJWK] = {}
        self._expires_at = 0.0
        self._lock = asyncio.Lock()

    async def get_key(self, kid: str) -> jwt.PyJWK | None:
        """kid에 해당하는 공개키를 돌려준다.

        Args:
            kid: ID 토큰 헤더의 키 ID.

        Returns:
            공개키. 새로 받아도 없으면 None.

        Raises:
            UpstreamError: 캐시가 만료됐는데 공개키를 받지 못했을 때.
        """
        if time.monotonic() >= self._expires_at:
            await self._refresh(force=False)
        key = self._keys.get(kid)
        if key is None:
            await self._refresh(force=True)
            key = self._keys.get(kid)
        return key

    async def _refresh(self, *, force: bool) -> None:
        async with self._lock:
            # 기다리는 동안 다른 요청이 이미 받아왔으면 다시 받지 않는다
            if not force and time.monotonic() < self._expires_at:
                return
            try:
                response = await self._http.get(self._url)
                response.raise_for_status()
                jwks = jwt.PyJWKSet.from_dict(response.json())
            except (httpx.HTTPError, ValueError, jwt.PyJWKSetError) as exc:
                logger.warning("Google 공개키 조회 실패", extra={"error": type(exc).__name__})
                if not self._keys:
                    raise UpstreamError from exc
                return
            self._keys = {key.key_id: key for key in jwks.keys if key.key_id}
            self._expires_at = time.monotonic() + _max_age(response.headers.get("cache-control"))


def _max_age(cache_control: str | None) -> int:
    match = _MAX_AGE.search(cache_control or "")
    return int(match.group(1)) if match else DEFAULT_JWKS_TTL_SECONDS


class GoogleIdTokenVerifier:
    """앱이 보낸 Google ID 토큰이 진짜이고 우리 서버용인지 확인한다 (T01)."""

    def __init__(
        self,
        jwks: GoogleJwksCache,
        web_client_id: str,
        allowed_azp: frozenset[str] = frozenset(),
    ) -> None:
        """검증기를 만든다.

        Args:
            jwks: Google 공개키 캐시.
            web_client_id: 웹 클라이언트 ID. ID 토큰의 aud가 정확히 이 값이어야 한다.
            allowed_azp: 허용할 앱(iOS·Android) 클라이언트 ID. 비어 있으면 azp를 검사하지 않는다.
        """
        self._jwks = jwks
        self._web_client_id = web_client_id
        self._allowed_azp = allowed_azp

    async def verify(self, id_token: str) -> GoogleIdentity:
        """ID 토큰의 서명과 내용을 검증한다.

        검사 항목: 서명(RS256만), iss, aud, azp(설정 시), exp·iat, sub·nonce 존재.
        nonce가 서버가 발급한 값인지는 호출하는 쪽(서비스)이 확인한다.

        Args:
            id_token: 앱이 Google에서 받은 ID 토큰.

        Returns:
            사용자 식별에 필요한 값.

        Raises:
            IdTokenInvalid: 검증에 실패했을 때. 실패 이유는 로그에만 남긴다.
            UpstreamError: Google 공개키를 받지 못했을 때.
        """
        try:
            header = jwt.get_unverified_header(id_token)
        except jwt.InvalidTokenError as exc:
            raise _invalid("malformed") from exc

        # 알고리즘은 토큰 헤더가 아니라 서버가 정한다. none·HS256 바꿔치기 차단.
        if header.get("alg") != "RS256" or not isinstance(header.get("kid"), str):
            raise _invalid("unexpected_header")

        key = await self._jwks.get_key(header["kid"])
        if key is None:
            raise _invalid("unknown_kid")

        try:
            claims: dict[str, Any] = jwt.decode(
                id_token,
                key,
                algorithms=["RS256"],
                audience=self._web_client_id,
                issuer=GOOGLE_ISSUERS,
                leeway=CLOCK_SKEW_SECONDS,
                options={"require": ["iss", "aud", "exp", "iat", "sub"]},
            )
        except jwt.ExpiredSignatureError as exc:
            raise _invalid("expired") from exc
        except jwt.InvalidAudienceError as exc:
            raise _invalid("audience") from exc
        except jwt.InvalidIssuerError as exc:
            raise _invalid("issuer") from exc
        except jwt.InvalidTokenError as exc:
            raise _invalid("invalid") from exc

        if self._allowed_azp and claims.get("azp") not in self._allowed_azp:
            raise _invalid("azp")

        nonce = claims.get("nonce")
        if not isinstance(nonce, str) or not nonce:
            raise _invalid("nonce_missing")

        email = claims.get("email") if claims.get("email_verified") is True else None
        name = claims.get("name")
        return GoogleIdentity(
            subject=str(claims["sub"]),
            nonce=nonce,
            email=email if isinstance(email, str) else None,
            name=name if isinstance(name, str) else None,
        )


def _invalid(reason: str) -> IdTokenInvalid:
    # 토큰 내용은 남기지 않고 실패 이유만 남긴다 (T25)
    logger.info("Google ID 토큰 거절", extra={"reason": reason})
    return IdTokenInvalid()
