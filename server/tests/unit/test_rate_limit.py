from unittest.mock import patch

from travel_copilot.core.rate_limit import SlidingWindowRateLimiter


def test_allows_up_to_limit_then_blocks() -> None:
    limiter = SlidingWindowRateLimiter()

    results = [limiter.hit("k", limit=2, window_seconds=60) for _ in range(3)]

    assert results[:2] == [None, None]
    assert results[2] is not None
    assert 0 < results[2] <= 60


def test_keys_are_independent() -> None:
    limiter = SlidingWindowRateLimiter()
    limiter.hit("a", limit=1, window_seconds=60)

    assert limiter.hit("b", limit=1, window_seconds=60) is None


def test_window_slides() -> None:
    limiter = SlidingWindowRateLimiter()
    with patch("travel_copilot.core.rate_limit.time.monotonic", return_value=100.0):
        limiter.hit("k", limit=1, window_seconds=60)
        assert limiter.hit("k", limit=1, window_seconds=60) is not None
    with patch("travel_copilot.core.rate_limit.time.monotonic", return_value=160.0):
        assert limiter.hit("k", limit=1, window_seconds=60) is None
