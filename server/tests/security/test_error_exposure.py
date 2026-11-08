"""T26: 에러 응답으로 내부 정보가 새지 않는지 확인한다."""

import pytest
from fastapi import FastAPI
from pydantic import BaseModel, ConfigDict

from tests.conftest import client_for, make_settings
from travel_copilot.main import create_app

SECRET = "super-secret-token-value"


class _Payload(BaseModel):
    model_config = ConfigDict(extra="forbid")

    count: int


def _app_with_test_routes(env: str = "local") -> FastAPI:
    app = create_app(make_settings(env=env))

    @app.get("/api/v1/_test/boom")
    async def boom() -> None:
        raise RuntimeError(f"DB password is {SECRET}")

    @app.post("/api/v1/_test/payload")
    async def payload(body: _Payload) -> dict[str, int]:
        return {"count": body.count}

    return app


async def test_unhandled_error_returns_generic_500() -> None:
    async with client_for(_app_with_test_routes()) as client:
        response = await client.get("/api/v1/_test/boom")

    assert response.status_code == 500
    assert response.json()["code"] == "internal_error"
    assert SECRET not in response.text
    assert "Traceback" not in response.text
    assert "RuntimeError" not in response.text


async def test_validation_error_does_not_echo_input() -> None:
    async with client_for(_app_with_test_routes()) as client:
        response = await client.post("/api/v1/_test/payload", json={"count": SECRET})

    assert response.status_code == 422
    body = response.json()
    assert body["code"] == "validation_error"
    assert body["errors"][0]["field"] == "body.count"
    assert SECRET not in response.text


async def test_unknown_field_is_rejected_without_echo() -> None:
    async with client_for(_app_with_test_routes()) as client:
        response = await client.post("/api/v1/_test/payload", json={"count": 1, "role": SECRET})

    assert response.status_code == 422
    assert SECRET not in response.text


@pytest.mark.parametrize("env", ["staging", "production"])
async def test_docs_disabled_outside_local(env: str) -> None:
    async with client_for(create_app(make_settings(env=env))) as client:
        docs = await client.get("/api/v1/docs")
        schema = await client.get("/api/v1/openapi.json")

    assert docs.status_code == 404
    assert schema.status_code == 404


async def test_docs_enabled_in_local() -> None:
    async with client_for(create_app(make_settings(env="local"))) as client:
        schema = await client.get("/api/v1/openapi.json")

    assert schema.status_code == 200
