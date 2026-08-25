from __future__ import annotations

import pytest

from backend.config import ConfigurationError, Settings


def base_environment(**overrides: str) -> dict[str, str]:
    environment = {
        "MONGO_URL": "mongodb://localhost:27017",
        "DB_NAME": "coach_max_test",
    }
    environment.update(overrides)
    return environment


def test_development_uses_safe_local_public_defaults() -> None:
    settings = Settings.from_environment(base_environment())

    assert settings.app_env == "development"
    assert settings.app_base_url == "http://localhost:3000"
    assert settings.cors_origins == ("http://localhost:3000",)


@pytest.mark.parametrize("missing", ["MONGO_URL", "DB_NAME"])
def test_required_database_configuration_fails_closed(missing: str) -> None:
    environment = base_environment()
    del environment[missing]

    with pytest.raises(ConfigurationError, match=missing):
        Settings.from_environment(environment)


def test_staging_requires_explicit_https_urls() -> None:
    with pytest.raises(ConfigurationError, match="APP_BASE_URL"):
        Settings.from_environment(base_environment(APP_ENV="staging"))

    with pytest.raises(ConfigurationError, match="HTTPS"):
        Settings.from_environment(
            base_environment(
                APP_ENV="staging",
                APP_BASE_URL="http://staging.example.test",
                CORS_ORIGINS="http://staging.example.test",
            )
        )


def test_production_rejects_wildcard_cors() -> None:
    with pytest.raises(ConfigurationError, match="wildcard"):
        Settings.from_environment(
            base_environment(
                APP_ENV="production",
                APP_BASE_URL="https://academy.example.test",
                CORS_ORIGINS="*",
            )
        )


def test_production_accepts_explicit_https_configuration() -> None:
    settings = Settings.from_environment(
        base_environment(
            APP_ENV="production",
            APP_BASE_URL="https://academy.example.test/",
            CORS_ORIGINS="https://academy.example.test,https://admin.example.test/",
        )
    )

    assert settings.app_base_url == "https://academy.example.test"
    assert settings.cors_origins == (
        "https://academy.example.test",
        "https://admin.example.test",
    )


def test_secret_values_are_excluded_from_settings_representation() -> None:
    marker = "synthetic-secret-value-not-real"
    settings = Settings.from_environment(
        base_environment(
            MONGO_URL=f"mongodb://user:{marker}@localhost:27017",
            RESEND_API_KEY=marker,
            EMERGENT_LLM_KEY=marker,
            THINKIFIC_API_KEY=marker,
            SENDER_EMAIL=f"{marker}@example.test",
            NOTIFICATION_EMAIL=f"{marker}@example.test",
            SUPER_ADMIN_EMAIL=f"{marker}@example.test",
            THINKIFIC_SUBDOMAIN=marker,
        )
    )

    assert marker not in repr(settings)


@pytest.mark.parametrize(
    "name,value",
    [
        ("APP_BASE_URL", "https://user:password@example.test"),
        ("CORS_ORIGINS", "https://user:password@example.test"),
        ("CORS_ORIGINS", "https://example.test/path"),
    ],
)
def test_public_urls_reject_credentials_and_paths(name: str, value: str) -> None:
    environment = base_environment(
        APP_ENV="production",
        APP_BASE_URL="https://academy.example.test",
        CORS_ORIGINS="https://academy.example.test",
    )
    environment[name] = value

    with pytest.raises(ConfigurationError):
        Settings.from_environment(environment)
