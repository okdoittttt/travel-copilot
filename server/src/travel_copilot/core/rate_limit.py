"""메모리 기반 요청 횟수 제한.

서버 1대 기준이다. 서버를 여러 대로 늘리면 Redis 같은 공유 저장소로 바꿔야 한다
(05-data-model 8절).
"""

import math
import time
from collections import deque
from collections.abc import Awaitable, Callable

from fastapi import Request

from travel_copilot.core.errors import RateLimited


class SlidingWindowRateLimiter:
    """키마다 최근 `window_seconds` 동안의 요청 수를 센다."""

    def __init__(self) -> None:
        """빈 카운터로 만든다."""
        self._hits: dict[str, deque[float]] = {}

    def hit(self, key: str, limit: int, window_seconds: float) -> float | None:
        """요청 한 번을 기록한다.

        이벤트 루프 안에서 await 없이 실행되므로 동시 요청 사이에 끼어드는 일이 없다.

        Args:
            key: 제한 단위 (예: "auth:127.0.0.1").
            limit: 창 안에서 허용하는 최대 요청 수.
            window_seconds: 창 길이(초).

        Returns:
            허용되면 None, 초과면 다시 시도할 수 있을 때까지 남은 초.
        """
        now = time.monotonic()
        hits = self._hits.setdefault(key, deque())
        while hits and now - hits[0] >= window_seconds:
            hits.popleft()
        if len(hits) >= limit:
            return window_seconds - (now - hits[0])
        hits.append(now)
        return None


def client_ip(request: Request) -> str:
    """요청한 클라이언트의 IP.

    uvicorn이 Nginx(FORWARDED_ALLOW_IPS)에서 온 `X-Forwarded-For`만 반영해서
    `request.client`를 채운다. 앱이 헤더로 IP를 속일 수 없다.

    Args:
        request: 현재 요청.

    Returns:
        IP 문자열. 알 수 없으면 "unknown".
    """
    return request.client.host if request.client else "unknown"


def limit_by_ip(
    scope: str, per_minute: Callable[[Request], int]
) -> Callable[[Request], Awaitable[None]]:
    """IP 기준으로 요청 횟수를 제한하는 FastAPI 의존성을 만든다.

    Args:
        scope: 제한을 묶는 이름 (예: "auth").
        per_minute: 요청에서 분당 허용 횟수를 꺼내는 함수 (설정값을 읽기 위해).

    Returns:
        초과 시 `RateLimited`를 던지는 의존성.
    """

    async def dependency(request: Request) -> None:
        limiter: SlidingWindowRateLimiter = request.app.state.rate_limiter
        retry_after = limiter.hit(f"{scope}:{client_ip(request)}", per_minute(request), 60)
        if retry_after is not None:
            raise RateLimited(retry_after_seconds=math.ceil(retry_after))

    return dependency
