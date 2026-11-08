from typing import Any

import httpx
import jwt
import pytest
import respx
from cryptography.hazmat.primitives.asymmetric import rsa

from travel_copilot.auth.google import GOOGLE_JWKS_URL, GoogleJwksCache
from travel_copilot.core.errors import UpstreamError


def _jwks(*kids: str) -> dict[str, Any]:
    keys = []
    for kid in kids:
        key = rsa.generate_private_key(public_exponent=65537, key_size=2048).public_key()
        jwk: dict[str, Any] = jwt.algorithms.RSAAlgorithm.to_jwk(key, as_dict=True)
        jwk.update({"kid": kid, "alg": "RS256", "use": "sig"})
        keys.append(jwk)
    return {"keys": keys}


async def test_caches_keys_until_max_age() -> None:
    with respx.mock() as mock:
        route = mock.get(GOOGLE_JWKS_URL).respond(
            json=_jwks("a"), headers={"Cache-Control": "max-age=3600"}
        )
        async with httpx.AsyncClient() as http:
            cache = GoogleJwksCache(http)
            assert await cache.get_key("a") is not None
            assert await cache.get_key("a") is not None

    assert route.call_count == 1


async def test_refetches_once_for_unknown_kid() -> None:
    with respx.mock() as mock:
        route = mock.get(GOOGLE_JWKS_URL)
        route.side_effect = [
            httpx.Response(200, json=_jwks("old")),
            httpx.Response(200, json=_jwks("old", "new")),
        ]
        async with httpx.AsyncClient() as http:
            cache = GoogleJwksCache(http)
            await cache.get_key("old")
            assert await cache.get_key("new") is not None

    assert route.call_count == 2


async def test_unknown_kid_after_refetch_returns_none() -> None:
    with respx.mock() as mock:
        mock.get(GOOGLE_JWKS_URL).respond(json=_jwks("a"))
        async with httpx.AsyncClient() as http:
            assert await GoogleJwksCache(http).get_key("missing") is None


async def test_fetch_failure_without_cache_raises_upstream_error() -> None:
    with respx.mock() as mock:
        mock.get(GOOGLE_JWKS_URL).respond(status_code=500)
        async with httpx.AsyncClient() as http:
            with pytest.raises(UpstreamError):
                await GoogleJwksCache(http).get_key("a")
