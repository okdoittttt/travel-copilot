from httpx import AsyncClient

from tests.conftest import client_for, make_settings
from travel_copilot.main import create_app


async def test_health_with_database_returns_ok(client: AsyncClient) -> None:
    response = await client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


async def test_health_without_database_returns_503() -> None:
    app = create_app(make_settings())
    async with client_for(app) as client:
        response = await client.get("/api/v1/health")

    assert response.status_code == 503
    assert response.headers["content-type"] == "application/problem+json"
    body = response.json()
    assert body["code"] == "unavailable"
    assert body["status"] == 503


async def test_health_response_has_no_internal_details(client: AsyncClient) -> None:
    response = await client.get("/api/v1/health")

    assert set(response.json()) == {"status"}
