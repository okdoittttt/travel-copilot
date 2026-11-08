"""자체 액세스 토큰(JWT) 발급·검증."""

import uuid
from datetime import UTC, datetime, timedelta

import jwt

from travel_copilot.auth.errors import TokenExpired, TokenInvalid

ISSUER = "travel-copilot"
AUDIENCE = "travel-copilot-api"
ALGORITHM = "HS256"


def create_access_token(user_id: uuid.UUID, secret: str, ttl_seconds: int) -> str:
    """액세스 토큰을 발급한다.

    JWT 본문은 누구나 읽을 수 있으므로 사용자 UUID 외의 개인정보는 넣지 않는다.

    Args:
        user_id: 토큰 주인.
        secret: HS256 서명 키.
        ttl_seconds: 유효 시간(초).

    Returns:
        서명된 JWT 문자열.
    """
    now = datetime.now(UTC)
    claims = {
        "sub": str(user_id),
        "iss": ISSUER,
        "aud": AUDIENCE,
        "iat": now,
        "exp": now + timedelta(seconds=ttl_seconds),
        "jti": uuid.uuid4().hex,
    }
    return jwt.encode(claims, secret, algorithm=ALGORITHM)


def decode_access_token(token: str, secret: str) -> uuid.UUID:
    """액세스 토큰을 검증하고 사용자 ID를 꺼낸다.

    알고리즘은 HS256만 받는다. 토큰 헤더의 alg를 믿지 않는다.

    Args:
        token: Authorization 헤더의 토큰.
        secret: HS256 서명 키.

    Returns:
        토큰 주인의 사용자 ID.

    Raises:
        TokenExpired: 만료됐을 때.
        TokenInvalid: 서명·형식·iss·aud가 틀렸을 때.
    """
    try:
        claims = jwt.decode(
            token,
            secret,
            algorithms=[ALGORITHM],
            audience=AUDIENCE,
            issuer=ISSUER,
            options={"require": ["sub", "iss", "aud", "exp", "iat"]},
        )
        return uuid.UUID(claims["sub"])
    except jwt.ExpiredSignatureError as exc:
        raise TokenExpired from exc
    except (jwt.InvalidTokenError, ValueError) as exc:
        raise TokenInvalid from exc
