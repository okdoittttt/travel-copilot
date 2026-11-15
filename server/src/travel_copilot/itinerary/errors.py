"""일정 도메인 예외."""

from typing import Any

from travel_copilot.core.errors import Conflict, InvalidInput


class DayItemLimit(Conflict):
    """하루 일정 항목이 최대 개수(50)에 이르렀을 때."""

    code = "day_item_limit"
    detail = "하루에 넣을 수 있는 일정은 최대 50개입니다."


class OrderMismatch(Conflict):
    """순서 변경 목록이 그날의 항목과 다를 때 (빠짐, 다른 날·다른 여행 항목, 중복)."""

    code = "order_mismatch"
    detail = "일정이 바뀌었습니다. 새로고침 후 다시 시도해주세요."

    def __init__(self, current: dict[str, Any]) -> None:
        """예외를 만든다.

        Args:
            current: 응답에 담을 그날의 최신 항목 목록.
        """
        super().__init__()
        self.current = current

    @property
    def extra(self) -> dict[str, Any]:
        """최신 목록을 담는다."""
        return {"current": self.current}


class DayOutOfRange(InvalidInput):
    """일정 날짜가 여행 기간 밖일 때."""

    detail = "일정 날짜는 여행 기간 안이어야 합니다."
