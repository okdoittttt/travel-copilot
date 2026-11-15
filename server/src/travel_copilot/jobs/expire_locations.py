"""30일 지난 Google 좌표를 지운다 (features/itinerary.md 5.4, Google 약관).

실행: `python -m travel_copilot.jobs.expire_locations`
자동 실행 스케줄은 운영 배포 때 정한다 (로드맵 5단계).
"""

import asyncio
import logging
from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from travel_copilot.core.config import DatabaseSettings
from travel_copilot.invites import repository as invite_repository
from travel_copilot.itinerary import repository
from travel_copilot.itinerary.service import LOCATION_MAX_AGE

logger = logging.getLogger(__name__)


async def expire_locations(session: AsyncSession, now: datetime | None = None) -> int:
    """받은 지 30일이 지난 좌표를 지우고 커밋한다.

    Args:
        session: DB 세션.
        now: 기준 시각 (테스트용). 없으면 현재.

    Returns:
        좌표를 지운 항목 수.
    """
    cutoff = (now or datetime.now(UTC)) - LOCATION_MAX_AGE
    count = await repository.clear_locations_before(session, cutoff)
    await session.commit()
    return count


async def purge_invites(session: AsyncSession, now: datetime | None = None) -> int:
    """만료된 지 30일이 지난 초대를 지우고 커밋한다 (features/invites.md 5.5).

    Args:
        session: DB 세션.
        now: 기준 시각 (테스트용). 없으면 현재.

    Returns:
        지운 초대 수.
    """
    count = await invite_repository.purge_ended(session, now or datetime.now(UTC))
    await session.commit()
    return count


async def run_periodically(
    sessionmaker: async_sessionmaker[AsyncSession], interval_seconds: float
) -> None:
    """서버가 떠 있는 동안 주기적으로 오래된 좌표와 끝난 초대를 지운다.

    좌표: features/routes-map.md 5.3, 초대: features/invites.md 5.5.

    서버 시작 직후 한 번 실행하고, 이후 `interval_seconds`마다 실행한다.
    한 번 실패해도 다음 주기에 다시 시도한다. 서버 여러 대로 늘리면 한 대만 실행하게 바꾼다.

    Args:
        sessionmaker: 앱의 세션 팩토리.
        interval_seconds: 실행 간격(초).
    """
    while True:
        try:
            async with sessionmaker() as session:
                count = await expire_locations(session)
            if count:
                logger.info("오래된 좌표 정리", extra={"count": count})
        except Exception:  # 주기 작업은 죽지 않고 다음 주기에 다시 시도
            logger.exception("좌표 정리 실패")
        try:
            async with sessionmaker() as session:
                count = await purge_invites(session)
            if count:
                logger.info("끝난 초대 정리", extra={"count": count})
        except Exception:
            logger.exception("초대 정리 실패")
        await asyncio.sleep(interval_seconds)


async def _main() -> None:
    settings = DatabaseSettings()  # 환경변수에서 읽음
    engine = create_async_engine(settings.database_url.get_secret_value())
    try:
        async with async_sessionmaker(engine)() as session:
            count = await expire_locations(session)
        logger.info("오래된 좌표 정리", extra={"count": count})
        print(f"좌표를 지운 항목: {count}")  # 운영자가 보는 명령 출력
    finally:
        await engine.dispose()


if __name__ == "__main__":
    asyncio.run(_main())
