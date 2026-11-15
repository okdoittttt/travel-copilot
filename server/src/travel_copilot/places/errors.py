"""장소 도메인 예외."""

from travel_copilot.core.errors import ServiceUnavailable


class PlacesUnavailable(ServiceUnavailable):
    """서버에 Places 키가 설정되지 않았을 때."""

    code = "places_unavailable"
    detail = "장소 검색을 사용할 수 없습니다."
