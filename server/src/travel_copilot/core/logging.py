"""JSON 한 줄 로그 설정."""

import json
import logging
import sys
from contextvars import ContextVar
from datetime import UTC, datetime
from typing import Any

# 현재 요청의 ID. 미들웨어가 요청 시작 시 설정한다.
request_id_var: ContextVar[str | None] = ContextVar("request_id", default=None)

# LogRecord의 기본 속성. 이 밖의 속성은 extra로 넘어온 값으로 보고 로그에 싣는다.
_RESERVED_ATTRS = frozenset(vars(logging.makeLogRecord({})).keys()) | {"message", "asctime"}


class JsonFormatter(logging.Formatter):
    """로그 레코드를 JSON 한 줄로 만든다.

    `logger.info("...", extra={"status": 200})`처럼 넘긴 값은 최상위 필드가 된다.
    무엇을 extra로 넘길지는 호출하는 쪽 책임이다. 토큰·개인정보는 넘기지 않는다.
    """

    def format(self, record: logging.LogRecord) -> str:
        """레코드를 JSON 문자열로 바꾼다.

        Args:
            record: 로깅 모듈이 만든 레코드.

        Returns:
            줄바꿈 없는 JSON 문자열.
        """
        payload: dict[str, Any] = {
            "time": datetime.fromtimestamp(record.created, UTC).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        request_id = request_id_var.get()
        if request_id is not None:
            payload["request_id"] = request_id
        for key, value in vars(record).items():
            if key not in _RESERVED_ATTRS and not key.startswith("_"):
                payload[key] = value
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False, default=str)


def configure_logging(level: str) -> None:
    """루트 로거를 JSON 형식으로 설정한다.

    uvicorn의 접근 로그는 쿼리 문자열을 그대로 남기므로 끄고, 요청 로그는
    미들웨어가 직접 남긴다.

    Args:
        level: 로그 레벨 이름 (예: "INFO").
    """
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level.upper())
    for name in ("uvicorn", "uvicorn.error"):
        uvicorn_logger = logging.getLogger(name)
        uvicorn_logger.handlers = []
        uvicorn_logger.propagate = True
    logging.getLogger("uvicorn.access").disabled = True
