"""환경변수 기반 설정."""

from enum import StrEnum
from functools import lru_cache

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# HS256 서명 키의 최소 길이. 짧은 키는 무차별 대입으로 찾을 수 있다.
MIN_JWT_SECRET_LENGTH = 32


class Environment(StrEnum):
    """서버가 실행되는 환경."""

    LOCAL = "local"
    STAGING = "staging"
    PRODUCTION = "production"


class DatabaseSettings(BaseSettings):
    """DB 접속 설정. 마이그레이션처럼 DB만 필요한 곳에서 단독으로 쓴다."""

    model_config = SettingsConfigDict(extra="ignore", frozen=True)

    database_url: SecretStr


class Settings(DatabaseSettings):
    """서버 설정.

    필수 값이 없으면 객체 생성 시점에 실패한다. 잘못된 설정으로 서버가 반쯤 뜨는
    상황을 막기 위해서다. 비밀값은 `SecretStr`로 감싸서 로그나 repr에 찍히지 않게 한다.
    """

    env: Environment
    log_level: str = "INFO"

    # 자체 토큰
    jwt_secret: SecretStr
    access_token_ttl_seconds: int = Field(default=900, ge=60, le=3600)
    refresh_token_ttl_days: int = Field(default=30, ge=1, le=90)

    # Google 로그인
    google_web_client_id: str = Field(min_length=1)
    # 쉼표로 구분한 iOS·Android 클라이언트 ID. 비어 있으면 azp를 검사하지 않는다.
    google_allowed_azp: str = ""

    # 요청 횟수 제한
    auth_rate_limit_per_minute: int = Field(default=10, ge=1)

    @field_validator("jwt_secret")
    @classmethod
    def _check_jwt_secret_length(cls, value: SecretStr) -> SecretStr:
        if len(value.get_secret_value()) < MIN_JWT_SECRET_LENGTH:
            msg = f"JWT_SECRET은 {MIN_JWT_SECRET_LENGTH}자 이상이어야 합니다"
            raise ValueError(msg)
        return value

    @property
    def docs_enabled(self) -> bool:
        """OpenAPI 문서를 노출할지 여부. 로컬에서만 켠다."""
        return self.env is Environment.LOCAL

    @property
    def google_allowed_azp_set(self) -> frozenset[str]:
        """ID 토큰 azp 검사에 쓸 클라이언트 ID 집합."""
        return frozenset(
            part.strip() for part in self.google_allowed_azp.split(",") if part.strip()
        )


@lru_cache
def get_settings() -> Settings:
    """환경변수에서 설정을 한 번만 읽어 돌려준다.

    Returns:
        프로세스 전체에서 공유하는 설정 객체.
    """
    return Settings()
