"""Provider-neutral runtime configuration for Coach Max.

Infisical, a deployment platform, or an ignored local ``.env`` file may populate
the process environment. Application code consumes only this module and never
needs an Infisical credential or SDK.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from os import environ as process_environment
from typing import Mapping, Optional, Tuple
from urllib.parse import urlsplit


class ConfigurationError(RuntimeError):
    """Raised when runtime configuration is absent or unsafe."""


SUPPORTED_ENVIRONMENTS = {"development", "staging", "production", "test"}


def _value(environment: Mapping[str, str], name: str) -> str:
    return environment.get(name, "").strip()


def _required(environment: Mapping[str, str], name: str) -> str:
    value = _value(environment, name)
    if not value:
        raise ConfigurationError(f"Required runtime configuration is missing: {name}")
    return value


def _validate_url(name: str, value: str, *, require_https: bool) -> str:
    parsed = urlsplit(value)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ConfigurationError(f"{name} must be an absolute HTTP(S) URL")
    if parsed.username or parsed.password:
        raise ConfigurationError(f"{name} must not contain embedded credentials")
    if require_https and parsed.scheme != "https":
        raise ConfigurationError(f"{name} must use HTTPS outside development and test")
    return value.rstrip("/")


def _cors_origins(raw_value: str, *, require_https: bool) -> Tuple[str, ...]:
    origins = tuple(origin.strip().rstrip("/") for origin in raw_value.split(",") if origin.strip())
    if not origins:
        raise ConfigurationError("CORS_ORIGINS must contain at least one explicit origin")
    if "*" in origins:
        raise ConfigurationError("CORS_ORIGINS must not use a wildcard")
    for origin in origins:
        parsed = urlsplit(origin)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ConfigurationError("CORS_ORIGINS entries must be absolute HTTP(S) origins")
        if parsed.username or parsed.password or parsed.path not in {"", "/"} or parsed.query or parsed.fragment:
            raise ConfigurationError("CORS_ORIGINS entries must not contain credentials, paths, queries, or fragments")
        if require_https and parsed.scheme != "https":
            raise ConfigurationError("CORS_ORIGINS entries must use HTTPS outside development and test")
    return origins


@dataclass(frozen=True)
class Settings:
    app_env: str
    mongo_url: str = field(repr=False)
    db_name: str
    cors_origins: Tuple[str, ...]
    app_base_url: str
    emergent_llm_key: Optional[str] = field(repr=False)
    resend_api_key: Optional[str] = field(repr=False)
    sender_email: str = field(repr=False)
    notification_email: str = field(repr=False)
    super_admin_email: str = field(repr=False)
    thinkific_api_key: Optional[str] = field(repr=False)
    thinkific_subdomain: str = field(repr=False)

    @classmethod
    def from_environment(cls, environment: Optional[Mapping[str, str]] = None) -> "Settings":
        source = process_environment if environment is None else environment
        app_env = _value(source, "APP_ENV") or "development"
        if app_env not in SUPPORTED_ENVIRONMENTS:
            allowed = ", ".join(sorted(SUPPORTED_ENVIRONMENTS))
            raise ConfigurationError(f"APP_ENV must be one of: {allowed}")

        local_mode = app_env in {"development", "test"}
        app_base_url = _value(source, "APP_BASE_URL")
        cors_value = _value(source, "CORS_ORIGINS")
        if local_mode:
            app_base_url = app_base_url or "http://localhost:3000"
            cors_value = cors_value or "http://localhost:3000"
        else:
            app_base_url = app_base_url or _required(source, "APP_BASE_URL")
            cors_value = cors_value or _required(source, "CORS_ORIGINS")

        require_https = not local_mode
        return cls(
            app_env=app_env,
            mongo_url=_required(source, "MONGO_URL"),
            db_name=_required(source, "DB_NAME"),
            cors_origins=_cors_origins(cors_value, require_https=require_https),
            app_base_url=_validate_url("APP_BASE_URL", app_base_url, require_https=require_https),
            emergent_llm_key=_value(source, "EMERGENT_LLM_KEY") or None,
            resend_api_key=_value(source, "RESEND_API_KEY") or None,
            sender_email=_value(source, "SENDER_EMAIL"),
            notification_email=_value(source, "NOTIFICATION_EMAIL").lower(),
            super_admin_email=_value(source, "SUPER_ADMIN_EMAIL").lower(),
            thinkific_api_key=_value(source, "THINKIFIC_API_KEY") or None,
            thinkific_subdomain=_value(source, "THINKIFIC_SUBDOMAIN"),
        )
