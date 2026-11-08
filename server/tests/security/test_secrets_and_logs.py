"""T24·T25: 비밀값과 요청 정보가 로그·repr에 남지 않는지 확인한다."""

import logging
from collections.abc import Iterator

import pytest

from tests.conftest import client_for, make_settings
from travel_copilot.core.logging import JsonFormatter
from travel_copilot.main import create_app

DB_PASSWORD = "db-password-should-not-leak"
QUERY_SECRET = "query-secret-token"
HEADER_SECRET = "header-secret-token"


class _ListHandler(logging.Handler):
    def __init__(self) -> None:
        super().__init__()
        self.lines: list[str] = []

    def emit(self, record: logging.LogRecord) -> None:
        self.lines.append(JsonFormatter().format(record))


def test_settings_secret_not_in_repr() -> None:
    settings = make_settings(database_url=f"postgresql+asyncpg://app:{DB_PASSWORD}@db:5432/app")

    assert DB_PASSWORD not in repr(settings)
    assert DB_PASSWORD not in str(settings)
    assert DB_PASSWORD not in settings.model_dump_json()


@pytest.fixture
def request_log() -> Iterator[_ListHandler]:
    handler = _ListHandler()
    logger = logging.getLogger("travel_copilot.request")
    logger.addHandler(handler)
    yield handler
    logger.removeHandler(handler)


async def test_request_log_excludes_query_and_headers(request_log: _ListHandler) -> None:
    app = create_app(make_settings())

    async with client_for(app) as client:
        await client.get(
            f"/api/v1/does-not-exist?token={QUERY_SECRET}",
            headers={"Authorization": f"Bearer {HEADER_SECRET}", "Cookie": f"s={HEADER_SECRET}"},
        )

    assert request_log.lines, "요청 로그가 남아야 한다"
    joined = "\n".join(request_log.lines)
    assert '"path": "/api/v1/does-not-exist"' in joined
    assert '"status": 404' in joined
    assert QUERY_SECRET not in joined
    assert HEADER_SECRET not in joined
