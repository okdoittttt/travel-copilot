"""여행 도메인 예외."""

from travel_copilot.core.errors import Conflict, InvalidInput


class OwnerCannotLeave(Conflict):
    """owner가 여행에서 나가려 할 때. 먼저 소유권을 넘겨야 한다."""

    code = "owner_cannot_leave"
    detail = "여행 소유자는 나갈 수 없습니다. 먼저 소유권을 넘겨주세요."


class OwnerRoleLocked(Conflict):
    """owner의 역할을 역할 변경 API로 바꾸려 할 때. 소유권 넘기기를 써야 한다."""

    code = "owner_role_locked"
    detail = "소유자의 역할은 소유권 넘기기로만 바꿀 수 있습니다."


class TripPeriodInvalid(InvalidInput):
    """수정 후 여행 기간이 규칙(시작 ≤ 종료, 최대 60일)에 맞지 않을 때."""

    detail = "여행 기간을 확인해주세요. 종료일은 시작일 이후, 최대 60일입니다."


class InvalidCursor(InvalidInput):
    """목록 커서를 해석할 수 없을 때 (변조됐거나 다른 API의 커서)."""

    detail = "목록 위치 값이 올바르지 않습니다."
