"""초대 도메인 예외."""

from travel_copilot.core.errors import AppError, Conflict

GONE_DETAIL = "더 이상 쓸 수 없는 초대 링크입니다. 초대한 사람에게 새 링크를 요청하세요."


class InviteLimit(Conflict):
    """여행의 열린 초대 링크가 이미 상한일 때."""

    code = "invite_limit"
    detail = "열린 초대 링크는 최대 5개입니다. 쓰지 않는 링크를 폐기해주세요."


class AlreadyMember(Conflict):
    """이미 멤버인 사람이 참여하려 할 때. 사용 횟수는 쓰지 않는다."""

    code = "already_member"
    detail = "이미 이 여행의 멤버입니다."


class TripMemberLimit(Conflict):
    """여행 멤버가 상한(20명)일 때."""

    code = "trip_member_limit"
    detail = "이 여행은 멤버가 가득 찼습니다."


class InviteGone(AppError):
    """끝난 초대 링크. 하위 클래스가 이유(code)를 정한다."""

    status = 410
    code = "invite_gone"
    title = "Gone"
    detail = GONE_DETAIL


class InviteRevoked(InviteGone):
    """폐기된 링크."""

    code = "invite_revoked"


class InviteExpired(InviteGone):
    """만료된 링크."""

    code = "invite_expired"


class InviteExhausted(InviteGone):
    """사용 횟수를 다 쓴 링크."""

    code = "invite_exhausted"
