"""랜덤 토큰 생성과 해시.

토큰·nonce처럼 추측되면 안 되는 값은 반드시 이 모듈로 만든다 (08-conventions S6·S8).
"""

import hashlib
import secrets

# 32바이트 = 256비트. 추측 불가능한 길이.
TOKEN_BYTES = 32


def generate_token() -> str:
    """URL에 넣어도 안전한 랜덤 토큰을 만든다.

    Returns:
        `secrets` 모듈로 만든 43자 문자열.
    """
    return secrets.token_urlsafe(TOKEN_BYTES)


def hash_token(token: str) -> str:
    """토큰을 DB에 저장할 형태(SHA-256 16진수)로 바꾼다.

    토큰 자체가 충분히 긴 랜덤 값이라 솔트 없는 SHA-256으로 충분하다
    (비밀번호처럼 사전 공격 대상이 아님).

    Args:
        token: 토큰 원문.

    Returns:
        64자 16진수 해시.
    """
    return hashlib.sha256(token.encode()).hexdigest()
