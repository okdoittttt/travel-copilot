import json
import logging

from travel_copilot.core.logging import JsonFormatter, request_id_var


def _record(message: str, **extra: object) -> logging.LogRecord:
    record = logging.makeLogRecord({"name": "test", "levelname": "INFO", "msg": message})
    for key, value in extra.items():
        setattr(record, key, value)
    return record


def test_json_formatter_outputs_single_line_json() -> None:
    output = JsonFormatter().format(_record("안녕", status=200))

    assert "\n" not in output
    payload = json.loads(output)
    assert payload["message"] == "안녕"
    assert payload["level"] == "INFO"
    assert payload["status"] == 200
    assert "time" in payload


def test_json_formatter_includes_request_id_when_set() -> None:
    token = request_id_var.set("abc123abc123abc123")
    try:
        payload = json.loads(JsonFormatter().format(_record("x")))
    finally:
        request_id_var.reset(token)

    assert payload["request_id"] == "abc123abc123abc123"


def test_json_formatter_omits_request_id_outside_request() -> None:
    payload = json.loads(JsonFormatter().format(_record("x")))

    assert "request_id" not in payload
