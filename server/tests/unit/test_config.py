import pytest
from pydantic import ValidationError

from tests.conftest import make_settings
from travel_copilot.core.config import Environment, Settings


def test_settings_missing_required_values_fails(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("ENV", raising=False)
    monkeypatch.delenv("DATABASE_URL", raising=False)

    with pytest.raises(ValidationError):
        Settings()


def test_settings_reads_environment_variables(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENV", "staging")
    monkeypatch.setenv("DATABASE_URL", "postgresql+asyncpg://u:p@db:5432/app")

    settings = Settings()

    assert settings.env is Environment.STAGING


def test_settings_rejects_unknown_environment() -> None:
    with pytest.raises(ValidationError):
        make_settings(env="dev")


@pytest.mark.parametrize(
    ("env", "expected"),
    [("local", True), ("staging", False), ("production", False)],
)
def test_docs_enabled_only_in_local(env: str, expected: bool) -> None:
    assert make_settings(env=env).docs_enabled is expected
