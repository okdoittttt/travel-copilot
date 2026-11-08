import pytest
from pydantic import ValidationError

from tests.conftest import make_settings
from travel_copilot.core.config import DatabaseSettings, Environment, Settings


def test_settings_missing_required_values_fails(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("ENV", raising=False)
    monkeypatch.delenv("DATABASE_URL", raising=False)

    with pytest.raises(ValidationError):
        Settings()


def test_settings_reads_environment_variables(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENV", "staging")
    monkeypatch.setenv("DATABASE_URL", "postgresql+asyncpg://u:p@db:5432/app")
    monkeypatch.setenv("JWT_SECRET", "x" * 32)
    monkeypatch.setenv("GOOGLE_WEB_CLIENT_ID", "web.apps.googleusercontent.com")
    monkeypatch.setenv("GOOGLE_ALLOWED_AZP", " ios-id , android-id ,")

    settings = Settings()

    assert settings.env is Environment.STAGING
    assert settings.google_allowed_azp_set == frozenset({"ios-id", "android-id"})


def test_settings_rejects_short_jwt_secret() -> None:
    with pytest.raises(ValidationError):
        make_settings(jwt_secret="too-short")


def test_database_settings_need_only_database_url(monkeypatch: pytest.MonkeyPatch) -> None:
    # 마이그레이션은 JWT 키 같은 다른 설정 없이 돌아야 한다
    monkeypatch.setenv("DATABASE_URL", "postgresql+asyncpg://u:p@db:5432/app")
    monkeypatch.delenv("JWT_SECRET", raising=False)

    assert DatabaseSettings().database_url.get_secret_value().endswith("/app")


def test_settings_rejects_unknown_environment() -> None:
    with pytest.raises(ValidationError):
        make_settings(env="dev")


@pytest.mark.parametrize(
    ("env", "expected"),
    [("local", True), ("staging", False), ("production", False)],
)
def test_docs_enabled_only_in_local(env: str, expected: bool) -> None:
    assert make_settings(env=env).docs_enabled is expected
