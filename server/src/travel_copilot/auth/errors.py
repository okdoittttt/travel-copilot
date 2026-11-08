"""인증 도메인 예외."""

from travel_copilot.core.errors import Unauthorized


class TokenMissing(Unauthorized):
    """Authorization 헤더가 없거나 Bearer 형식이 아닐 때."""

    code = "token_missing"
    detail = "인증이 필요합니다."


class TokenExpired(Unauthorized):
    """액세스 토큰이 만료됐을 때. 앱은 이 code를 보고 토큰을 갱신한다."""

    code = "token_expired"
    detail = "인증이 만료되었습니다."


class TokenInvalid(Unauthorized):
    """토큰이 위조·변조됐거나, 폐기됐거나, 사용자가 없을 때."""

    code = "token_invalid"
    detail = "유효하지 않은 인증입니다."


class IdTokenInvalid(Unauthorized):
    """소셜 로그인 ID 토큰 검증에 실패했을 때.

    어떤 검사에서 실패했는지는 응답에 넣지 않는다 (공격자에게 힌트를 주지 않기 위해).
    이유는 서버 로그에만 남긴다.
    """

    code = "id_token_invalid"
    detail = "로그인하지 못했습니다. 다시 시도해주세요."


class NonceInvalid(Unauthorized):
    """nonce가 없거나, 서버가 발급하지 않았거나, 만료·사용됐을 때."""

    code = "nonce_invalid"
    detail = "로그인 요청이 만료되었습니다. 다시 시도해주세요."
