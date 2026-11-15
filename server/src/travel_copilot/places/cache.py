"""장소 상세에서 받은 좌표를 잠깐 기억한다 (features/itinerary.md 5.2).

장소를 고를 때 받은 좌표를 일정 저장에 다시 쓰려고, Google을 두 번 부르지 않게 한다.
좌표는 약관상 30일까지 저장할 수 있고, 이름·주소는 담지 않는다.
"""

import time
import uuid

from travel_copilot.places.schemas import LatLng

TTL_SECONDS = 600
MAX_ENTRIES = 10_000


class LocationCache:
    """(사용자, place_id) → 좌표. 10분 뒤 만료. 서버 메모리라 재시작하면 비워진다."""

    def __init__(self, ttl_seconds: float = TTL_SECONDS, max_entries: int = MAX_ENTRIES) -> None:
        """빈 캐시를 만든다.

        Args:
            ttl_seconds: 보관 시간.
            max_entries: 최대 개수. 넘으면 오래된 것부터 지운다.
        """
        self._ttl = ttl_seconds
        self._max = max_entries
        self._items: dict[tuple[uuid.UUID, str], tuple[float, LatLng]] = {}

    def put(self, user_id: uuid.UUID, place_id: str, location: LatLng) -> None:
        """좌표를 기억한다.

        Args:
            user_id: 장소를 고른 사용자.
            place_id: Google 장소 ID.
            location: Google에서 받은 좌표.
        """
        now = time.monotonic()
        self._items.pop((user_id, place_id), None)
        self._items[(user_id, place_id)] = (now + self._ttl, location)
        if len(self._items) > self._max:
            self._prune(now)

    def get(self, user_id: uuid.UUID, place_id: str) -> LatLng | None:
        """기억한 좌표를 꺼낸다.

        Args:
            user_id: 사용자.
            place_id: Google 장소 ID.

        Returns:
            만료 전이면 좌표, 없거나 만료됐으면 None.
        """
        entry = self._items.get((user_id, place_id))
        if entry is None:
            return None
        expires_at, location = entry
        if time.monotonic() >= expires_at:
            del self._items[(user_id, place_id)]
            return None
        return location

    def _prune(self, now: float) -> None:
        for key in [k for k, (exp, _) in self._items.items() if exp <= now]:
            del self._items[key]
        # 그래도 많으면 넣은 순서(오래된 것)부터 지운다
        while len(self._items) > self._max:
            del self._items[next(iter(self._items))]
