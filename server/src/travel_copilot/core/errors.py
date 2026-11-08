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
) -> JSONResponse:
    """RFC 9457 형식 에러 응답을 만든다.

    Args:
        status: HTTP 상태 코드.
        code: 앱이 분기에 쓰는 고정 문자열.
        title: 상태를 짧게 설명하는 영문 제목.
        detail: 사용자에게 보여도 되는 설명.
        extra: 본문에 더할 필드 (예: 검증 실패 목록).

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
    return JSONResponse(status_code=status, content=body, media_type=PROBLEM_JSON)


async def _handle_app_error(_: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, AppError)  # noqa: S101  # 등록 시 타입으로 보장됨
    return problem_response(exc.status, exc.code, exc.title, exc.detail)


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
