"""환경변수 기반 설정."""

from enum import StrEnum
from functools import lru_cache

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Environment(StrEnum):
    """서버가 실행되는 환경."""

    LOCAL = "local"
    STAGING = "staging"
    PRODUCTION = "production"


class Settings(BaseSettings):
    """서버 설정.

    필수 값이 없으면 객체 생성 시점에 실패한다. 잘못된 설정으로 서버가 반쯤 뜨는
    상황을 막기 위해서다. 비밀값은 `SecretStr`로 감싸서 로그나 repr에 찍히지 않게 한다.
    """

    model_config = SettingsConfigDict(extra="ignore", frozen=True)

    env: Environment
    database_url: SecretStr
    log_level: str = "INFO"

    @property
    def docs_enabled(self) -> bool:
        """OpenAPI 문서를 노출할지 여부. 로컬에서만 켠다."""
        return self.env is Environment.LOCAL


@lru_cache
def get_settings() -> Settings:
    """환경변수에서 설정을 한 번만 읽어 돌려준다.

    Returns:
        프로세스 전체에서 공유하는 설정 객체.
    """
    return Settings()
