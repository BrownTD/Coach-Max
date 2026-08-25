#!/usr/bin/env python3
"""Validate injected configuration without printing any configured values."""

from __future__ import annotations

import sys
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPOSITORY_ROOT))

from backend.config import ConfigurationError, Settings


def main() -> int:
    try:
        settings = Settings.from_environment()
    except ConfigurationError as exc:
        print(f"Runtime configuration rejected: {exc}")
        return 1

    print(f"Runtime configuration accepted for {settings.app_env}; secret values were not displayed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
