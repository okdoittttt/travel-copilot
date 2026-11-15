"""초대 토큰 생성·해시 (features/invites.md 5.1)."""

import hashlib
import re
import secrets

# secrets.token_urlsafe(32)의 결과: 256비트, URL-safe base64 43자
TOKEN_BYTES = 32
TOKEN_PATTERN = re.compile(r"^[A-Za-z0-9_-]{43}$")


def new_token() -> str:
    """추측할 수 없는 초대 토큰을 만든다.

    Returns:
        43자 URL-safe 문자열 (256비트).
    """
    return secrets.token_urlsafe(TOKEN_BYTES)


def hash_token(token: str) -> str:
    """토큰의 SHA-256 16진수 문자열. DB에는 이 값만 저장한다.

    토큰이 256비트 랜덤이라 대입이 불가능하므로 느린 해시가 필요 없고,
    빠른 해시여야 UNIQUE 인덱스로 바로 찾을 수 있다.

    Args:
        token: 토큰 원문.

    Returns:
        64자 16진수.
    """
    return hashlib.sha256(token.encode()).hexdigest()


def is_well_formed(token: str) -> bool:
    """토큰 형식(43자 URL-safe)이 맞는지 확인한다.

    Args:
        token: 받은 문자열.

    Returns:
        형식이 맞으면 True.
    """
    return TOKEN_PATTERN.fullmatch(token) is not None
