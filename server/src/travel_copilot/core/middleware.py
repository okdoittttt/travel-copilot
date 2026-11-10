"""요청 ID 부여와 요청 로그 미들웨어."""

import logging
import re
import time
import uuid

from starlette.types import ASGIApp, Message, Receive, Scope, Send

from travel_copilot.core.logging import request_id_var

logger = logging.getLogger("travel_copilot.request")

REQUEST_ID_HEADER = b"x-request-id"
CACHE_CONTROL_HEADER = b"cache-control"
# Nginx의 $request_id(32자리 16진수)나 UUID만 받는다. 그 외 값은 버리고 새로 만든다.
_VALID_REQUEST_ID = re.compile(r"^[A-Za-z0-9-]{16,64}$")


class RequestContextMiddleware:
    """요청마다 ID를 정하고, 끝나면 요청 로그를 한 줄 남긴다.

    요청 ID는 Nginx가 넣어준 `X-Request-ID`를 쓰고, 없거나 형식이 이상하면 새로 만든다.
    로그에는 메서드, 경로, 상태, 소요 시간만 남긴다. 쿼리 문자열·헤더·본문은
    토큰이나 개인정보가 섞일 수 있어서 남기지 않는다.
    """

    def __init__(self, app: ASGIApp) -> None:
        """미들웨어를 만든다.

        Args:
            app: 감쌀 ASGI 앱.
        """
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        """ASGI 요청을 처리한다.

        Args:
            scope: ASGI 연결 정보.
            receive: 요청 메시지를 받는 함수.
            send: 응답 메시지를 보내는 함수.
        """
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request_id = _pick_request_id(scope)
        token = request_id_var.set(request_id)
        started = time.perf_counter()
        status_code = 500

        async def send_with_request_id(message: Message) -> None:
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
                headers = list(message.get("headers", []))
                headers.append((REQUEST_ID_HEADER, request_id.encode()))
                message["headers"] = headers
            await send(message)

        try:
            await self.app(scope, receive, send_with_request_id)
        finally:
            logger.info(
                "request",
                extra={
                    "method": scope["method"],
                    "path": scope["path"],
                    "status": status_code,
                    "duration_ms": round((time.perf_counter() - started) * 1000, 1),
                },
            )
            request_id_var.reset(token)


def _pick_request_id(scope: Scope) -> str:
    for name, value in scope.get("headers", []):
        if name == REQUEST_ID_HEADER:
            candidate: str = bytes(value).decode("latin-1")
            if _VALID_REQUEST_ID.fullmatch(candidate):
                return candidate
            break
    return uuid.uuid4().hex


class NoStoreMiddleware:
    """모든 응답에 `Cache-Control: no-store`를 붙인다.

    응답에는 개인정보(여행 기간, 멤버 이름)와 캐시가 제한된 Google 데이터가 들어간다.
    중간 프록시나 기기 HTTP 캐시에 남지 않게 한다 (06-api 1절).
    """

    def __init__(self, app: ASGIApp) -> None:
        """미들웨어를 만든다.

        Args:
            app: 감쌀 ASGI 앱.
        """
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        """ASGI 요청을 처리한다.

        Args:
            scope: ASGI 연결 정보.
            receive: 요청 메시지를 받는 함수.
            send: 응답 메시지를 보내는 함수.
        """
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        async def send_with_no_store(message: Message) -> None:
            if message["type"] == "http.response.start":
                headers = [
                    (name, value)
                    for name, value in message.get("headers", [])
                    if name.lower() != CACHE_CONTROL_HEADER
                ]
                headers.append((CACHE_CONTROL_HEADER, b"no-store"))
                message["headers"] = headers
            await send(message)

        await self.app(scope, receive, send_with_no_store)
