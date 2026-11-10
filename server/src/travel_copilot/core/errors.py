"""도메인 예외와 RFC 9457 에러 응답 변환."""

import logging
from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger(__name__)

PROBLEM_JSON = "application/problem+json"

# 프레임워크가 직접 만드는 HTTP 에러(없는 경로 등)에 붙일 code.
_HTTP_STATUS_CODES: dict[int, tuple[str, str]] = {
    400: ("invalid_request", "Bad Request"),
    401: ("token_missing", "Unauthorized"),
    403: ("forbidden", "Forbidden"),
    404: ("not_found", "Not Found"),
    405: ("method_not_allowed", "Method Not Allowed"),
    413: ("payload_too_large", "Payload Too Large"),
    415: ("unsupported_media_type", "Unsupported Media Type"),
}


class AppError(Exception):
    """서비스 계층이 던지는 도메인 예외의 베이스.

    서비스는 HTTP를 모른다. 대신 이 예외의 속성으로 상태 코드와 앱용 code를 정하고,
    전역 핸들러가 RFC 9457 응답으로 바꾼다.

    Attributes:
        status: HTTP 상태 코드.
        code: 앱이 분기에 쓰는 고정 문자열.
        title: 상태를 짧게 설명하는 영문 제목.
        detail: 사용자에게 보여도 되는 설명. 내부 정보를 넣지 않는다.
    """

    status: int = 400
    code: str = "invalid_request"
    title: str = "Bad Request"
    detail: str = "요청을 처리할 수 없습니다."

    def __init__(self, detail: str | None = None) -> None:
        """예외를 만든다.

        Args:
            detail: 기본 설명 대신 쓸 문구. 사용자에게 그대로 보인다.
        """
        if detail is not None:
            self.detail = detail
        super().__init__(self.detail)

    @property
    def headers(self) -> dict[str, str]:
        """응답에 더할 헤더. 하위 클래스가 필요할 때 덮어쓴다."""
        return {}

    @property
    def extra(self) -> dict[str, Any]:
        """응답 본문에 더할 필드. 하위 클래스가 필요할 때 덮어쓴다."""
        return {}


class InvalidInput(AppError):
    """스키마 검증을 통과했지만 다른 값과 함께 봤을 때 맞지 않는 입력.

    Pydantic 검증 실패와 같은 422 `validation_error`로 응답한다.
    """

    status = 422
    code = "validation_error"
    title = "Unprocessable Content"
    detail = "입력값을 확인해주세요."


class NotFound(AppError):
    """리소스가 없거나, 요청자가 볼 권한이 없을 때.

    비멤버에게도 이 예외를 쓴다. 두 경우의 응답이 같아야 리소스가 있는지조차
    알려주지 않을 수 있다 (06-api 2절, T06).
    """

    status = 404
    code = "not_found"
    title = "Not Found"
    detail = "찾을 수 없습니다."


class Forbidden(AppError):
    """멤버지만 역할이 부족할 때."""

    status = 403
    code = "forbidden"
    title = "Forbidden"
    detail = "권한이 없습니다."


class Conflict(AppError):
    """현재 상태와 맞지 않는 요청. 하위 클래스가 code를 정한다."""

    status = 409
    code = "conflict"
    title = "Conflict"
    detail = "현재 상태에서 처리할 수 없는 요청입니다."


class VersionConflict(Conflict):
    """수정 요청의 version이 서버 값과 다를 때. 본문 `current`에 최신 데이터를 담는다."""

    code = "version_conflict"
    title = "Version conflict"
    detail = "다른 멤버가 먼저 수정했습니다."

    def __init__(self, current: dict[str, Any]) -> None:
        """예외를 만든다.

        Args:
            current: 응답에 담을 최신 데이터 (JSON으로 바꿀 수 있는 값).
        """
        super().__init__()
        self.current = current

    @property
    def extra(self) -> dict[str, Any]:
        """최신 데이터를 담는다."""
        return {"current": self.current}


class Unauthorized(AppError):
    """인증 실패의 베이스. 응답에 `WWW-Authenticate` 헤더를 붙인다."""

    status = 401
    code = "token_invalid"
    title = "Unauthorized"
    detail = "인증이 필요합니다."

    @property
    def headers(self) -> dict[str, str]:
        """Bearer 인증이 필요하다고 알린다."""
        return {"WWW-Authenticate": "Bearer"}


class RateLimited(AppError):
    """요청 횟수 제한을 넘었을 때."""

    status = 429
    code = "rate_limited"
    title = "Too Many Requests"
    detail = "잠시 후 다시 시도해주세요."

    def __init__(self, retry_after_seconds: int) -> None:
        """예외를 만든다.

        Args:
            retry_after_seconds: 다시 시도할 수 있을 때까지 남은 초.
        """
        super().__init__()
        self.retry_after_seconds = max(1, retry_after_seconds)

    @property
    def headers(self) -> dict[str, str]:
        """언제 다시 시도할 수 있는지 알린다."""
        return {"Retry-After": str(self.retry_after_seconds)}


class UpstreamError(AppError):
    """Google 등 외부 서비스 호출이 실패했을 때."""

    status = 502
    code = "upstream_error"
    title = "Bad Gateway"
    detail = "외부 서비스에 연결하지 못했습니다. 잠시 후 다시 시도해주세요."


class ServiceUnavailable(AppError):
    """DB 등 필수 구성 요소를 쓸 수 없을 때."""

    status = 503
    code = "unavailable"
    title = "Service Unavailable"
    detail = "일시적으로 서비스를 이용할 수 없습니다."


def problem_response(
    status: int,
    code: str,
    title: str,
    detail: str,
    extra: dict[str, Any] | None = None,
    headers: dict[str, str] | None = None,
) -> JSONResponse:
    """RFC 9457 형식 에러 응답을 만든다.

    Args:
        status: HTTP 상태 코드.
        code: 앱이 분기에 쓰는 고정 문자열.
        title: 상태를 짧게 설명하는 영문 제목.
        detail: 사용자에게 보여도 되는 설명.
        extra: 본문에 더할 필드 (예: 검증 실패 목록).
        headers: 응답에 더할 헤더 (예: Retry-After).

    Returns:
        `application/problem+json` 응답.
    """
    body: dict[str, Any] = {
        "type": "about:blank",
        "title": title,
        "status": status,
        "code": code,
        "detail": detail,
    }
    if extra:
        body.update(extra)
    return JSONResponse(status_code=status, content=body, media_type=PROBLEM_JSON, headers=headers)


async def _handle_app_error(_: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, AppError)  # noqa: S101  # 등록 시 타입으로 보장됨
    return problem_response(
        exc.status, exc.code, exc.title, exc.detail, extra=exc.extra, headers=exc.headers
    )


async def _handle_validation_error(_: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, RequestValidationError)  # noqa: S101
    # Pydantic 기본 에러에는 사용자가 보낸 입력값(input)과 부가 정보(ctx)가 들어 있다.
    # 토큰 같은 값이 응답으로 되돌아가지 않게 위치와 이유만 남긴다.
    errors = [
        {
            "field": ".".join(str(part) for part in error.get("loc", ())),
            "type": error.get("type", "value_error"),
            "message": error.get("msg", ""),
        }
        for error in exc.errors()
    ]
    return problem_response(
        422,
        "validation_error",
        "Unprocessable Content",
        "입력값을 확인해주세요.",
        extra={"errors": errors},
    )


async def _handle_http_error(_: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, StarletteHTTPException)  # noqa: S101
    code, title = _HTTP_STATUS_CODES.get(exc.status_code, ("http_error", "Error"))
    return problem_response(exc.status_code, code, title, "요청을 처리할 수 없습니다.")


async def _handle_unexpected_error(_: Request, exc: Exception) -> JSONResponse:
    # 원인은 서버 로그에만 남기고, 응답에는 고정 문구만 보낸다.
    logger.exception("처리되지 않은 예외", exc_info=exc)
    return problem_response(
        500, "internal_error", "Internal Server Error", "서버에서 문제가 발생했습니다."
    )


def register_error_handlers(app: FastAPI) -> None:
    """전역 예외 핸들러를 앱에 등록한다.

    Args:
        app: 핸들러를 등록할 FastAPI 앱.
    """
    app.add_exception_handler(AppError, _handle_app_error)
    app.add_exception_handler(RequestValidationError, _handle_validation_error)
    app.add_exception_handler(StarletteHTTPException, _handle_http_error)
    app.add_exception_handler(Exception, _handle_unexpected_error)
