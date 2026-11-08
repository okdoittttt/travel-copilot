from httpx import AsyncClient


async def test_unknown_path_returns_problem_404(client_without_db: AsyncClient) -> None:
    response = await client_without_db.get("/api/v1/does-not-exist")

    assert response.status_code == 404
    assert response.headers["content-type"] == "application/problem+json"
    assert response.json() == {
        "type": "about:blank",
        "title": "Not Found",
        "status": 404,
        "code": "not_found",
        "detail": "요청을 처리할 수 없습니다.",
    }


async def test_wrong_method_returns_problem_405(client_without_db: AsyncClient) -> None:
    response = await client_without_db.post("/api/v1/health")

    assert response.status_code == 405
    assert response.json()["code"] == "method_not_allowed"


async def test_response_has_generated_request_id(client_without_db: AsyncClient) -> None:
    response = await client_without_db.get("/api/v1/does-not-exist")

    assert len(response.headers["x-request-id"]) == 32


async def test_valid_incoming_request_id_is_kept(client_without_db: AsyncClient) -> None:
    request_id = "0123456789abcdef0123456789abcdef"

    response = await client_without_db.get(
        "/api/v1/does-not-exist", headers={"X-Request-ID": request_id}
    )

    assert response.headers["x-request-id"] == request_id


async def test_malformed_incoming_request_id_is_replaced(client_without_db: AsyncClient) -> None:
    response = await client_without_db.get(
        "/api/v1/does-not-exist", headers={"X-Request-ID": "bad id\r\ninjected: yes"}
    )

    assert response.headers["x-request-id"] != "bad id\r\ninjected: yes"
    assert len(response.headers["x-request-id"]) == 32
