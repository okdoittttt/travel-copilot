"""여행 권한 확인 의존성 (features/trips.md 5.1).

`/trips/{trip_id}`가 들어간 모든 라우트는 이 모듈의 `TripViewer`·`TripEditor`·`TripOwner`
(또는 잠금 버전) 중 하나를 써야 한다. 빠뜨리면
`tests/security/test_trips_authz.py::test_all_trip_routes_require_membership`이 실패한다.
"""

import uuid
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from travel_copilot.auth.dependencies import CurrentUser
from travel_copilot.core.db import get_session
from travel_copilot.core.errors import Forbidden, NotFound
from travel_copilot.trips import repository
from travel_copilot.trips.models import Trip, TripMember, TripRole

# 라우트 전수 검사 테스트가 이 표시로 권한 확인 의존성을 찾는다
TRIP_GUARD_MARKER = "__trip_guard__"


@dataclass(frozen=True, slots=True)
class TripAccess:
    """권한 확인을 통과한 요청의 여행과 요청자 멤버십.

    서비스의 여행 쓰기 함수는 이 값을 인자로 받는다. 권한 확인을 거치지 않고는
    여행을 바꾸는 함수를 부를 수 없게 하기 위해서다.
    """

    trip: Trip
    membership: TripMember

    @property
    def role(self) -> TripRole:
        """요청자의 역할."""
        return self.membership.role


def require_trip_member(
    minimum: TripRole, *, lock: bool = False
) -> Callable[..., Awaitable[TripAccess]]:
    """요청자가 여행 멤버이고 최소 역할 이상인지 확인하는 의존성을 만든다.

    멤버십은 요청마다 DB에서 읽는다. 그래서 내보낸 멤버는 다음 요청부터 바로 막힌다 (T08).

    Args:
        minimum: 필요한 최소 역할.
        lock: True면 여행 행을 잠근 뒤 멤버십을 읽는다. 멤버 구성(역할, 소유권, 멤버 삭제)을
            바꾸는 라우트에 쓴다. 같은 여행의 이런 작업이 순서대로 처리되고,
            잠금을 기다리는 동안 바뀐 역할도 반영된다.

    Returns:
        FastAPI 의존성 함수.
    """

    async def dependency(
        trip_id: uuid.UUID,
        user: CurrentUser,
        session: Annotated[AsyncSession, Depends(get_session)],
    ) -> TripAccess:
        """여행 권한을 확인한다.

        Raises:
            NotFound: 여행이 없거나 요청자가 멤버가 아닐 때 (두 경우를 구별하지 않는다).
            Forbidden: 멤버지만 역할이 부족할 때.
        """
        trip = await repository.get_trip(session, trip_id, lock=lock)
        membership = (
            await repository.get_membership(session, trip_id, user.id) if trip is not None else None
        )
        if trip is None or membership is None:
            raise NotFound
        if not membership.role.at_least(minimum):
            raise Forbidden
        return TripAccess(trip=trip, membership=membership)

    setattr(dependency, TRIP_GUARD_MARKER, True)
    return dependency


TripViewer = Annotated[TripAccess, Depends(require_trip_member(TripRole.VIEWER))]
TripEditor = Annotated[TripAccess, Depends(require_trip_member(TripRole.EDITOR))]
TripOwner = Annotated[TripAccess, Depends(require_trip_member(TripRole.OWNER))]
TripViewerLocked = Annotated[TripAccess, Depends(require_trip_member(TripRole.VIEWER, lock=True))]
TripOwnerLocked = Annotated[TripAccess, Depends(require_trip_member(TripRole.OWNER, lock=True))]
