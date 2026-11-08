import respx
from cryptography.hazmat.primitives.asymmetric import rsa
from httpx import AsyncClient

from tests.conftest import bearer, google_login


async def test_nonce_returns_random_value(client: AsyncClient) -> None:
    first = (await client.post("/api/v1/auth/nonce")).json()
    second = (await client.post("/api/v1/auth/nonce")).json()

    assert first["expires_in"] == 300
    assert len(first["nonce"]) >= 40
    assert first["nonce"] != second["nonce"]


async def test_first_login_creates_user_with_display_name(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    body = await google_login(client, google_private_key, display_name="  홍길동  ")

    assert body["is_new_user"] is True
    assert body["user"]["display_name"] == "홍길동"
    assert body["expires_in"] == 900
    assert set(body) == {
        "access_token",
        "token_type",
        "expires_in",
        "refresh_token",
        "user",
        "is_new_user",
    }


async def test_second_login_returns_same_user(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    first = await google_login(client, google_private_key)
    second = await google_login(client, google_private_key, display_name="무시됨")

    assert second["is_new_user"] is False
    assert second["user"]["id"] == first["user"]["id"]
    assert second["user"]["display_name"] == first["user"]["display_name"]


async def test_login_without_display_name_uses_google_name(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    body = await google_login(client, google_private_key)

    assert body["user"]["display_name"] == "Google 이름"


async def test_login_without_any_name_uses_default(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    body = await google_login(client, google_private_key, name=None)

    assert body["user"]["display_name"] == "여행자"


async def test_unverified_email_is_not_stored(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    login = await google_login(client, google_private_key, email_verified=False)

    me = (await client.get("/api/v1/me", headers=bearer(login["access_token"]))).json()

    assert me["email"] is None


async def test_login_rejects_unknown_fields(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/google/login", json={"id_token": "x", "role": "admin"}
    )

    assert response.status_code == 422


async def test_logout_requires_token(client: AsyncClient) -> None:
    response = await client.post("/api/v1/auth/logout", json={"refresh_token": "x"})

    assert response.status_code == 401


async def test_get_me(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    login = await google_login(client, google_private_key)

    response = await client.get("/api/v1/me", headers=bearer(login["access_token"]))

    assert response.status_code == 200
    assert response.json() == {
        "id": login["user"]["id"],
        "display_name": "Google 이름",
        "email": "traveler@example.com",
    }


async def test_update_me_display_name(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    login = await google_login(client, google_private_key)
    headers = bearer(login["access_token"])

    response = await client.patch("/api/v1/me", json={"display_name": " 길동 "}, headers=headers)

    assert response.status_code == 200
    assert response.json()["display_name"] == "길동"


async def test_update_me_rejects_invalid_input(
    client: AsyncClient, google_jwks: respx.MockRouter, google_private_key: rsa.RSAPrivateKey
) -> None:
    login = await google_login(client, google_private_key)
    headers = bearer(login["access_token"])

    empty = await client.patch("/api/v1/me", json={"display_name": "   "}, headers=headers)
    too_long = await client.patch("/api/v1/me", json={"display_name": "가" * 51}, headers=headers)
    extra = await client.patch(
        "/api/v1/me", json={"display_name": "a", "email": "x@y.z"}, headers=headers
    )

    assert (empty.status_code, too_long.status_code, extra.status_code) == (422, 422, 422)


async def test_update_me_requires_token(client: AsyncClient) -> None:
    response = await client.patch("/api/v1/me", json={"display_name": "a"})

    assert response.status_code == 401
