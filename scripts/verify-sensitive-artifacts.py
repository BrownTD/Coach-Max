#!/usr/bin/env python3
"""Reject known-sensitive artifact classes from the tracked Git tree.

This narrow containment check complements, but does not replace, secret scanning.
It intentionally reports paths only and never reads or prints secret values.
"""

from __future__ import annotations

import subprocess
from pathlib import PurePosixPath


ALLOWED_ENV_FILES = {
    PurePosixPath("backend/.env.example"),
    PurePosixPath("frontend/.env.example"),
}
FORBIDDEN_EXACT_PATHS = {
    PurePosixPath("auth_testing.md"),
    PurePosixPath("memory/test_credentials.md"),
}
FORBIDDEN_SUFFIXES = {".key", ".pem"}
GENERATED_ROOTS = {
    PurePosixPath("backend/uploads"),
    PurePosixPath("test_reports"),
}


def tracked_paths() -> list[PurePosixPath]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        check=True,
        capture_output=True,
    )
    return [PurePosixPath(raw.decode()) for raw in result.stdout.split(b"\0") if raw]


def is_environment_file(path: PurePosixPath) -> bool:
    name = path.name
    return name == ".env" or name.startswith(".env.") or name.endswith(".env")


def is_generated_artifact(path: PurePosixPath) -> bool:
    for root in GENERATED_ROOTS:
        if path == root:
            return True
        if root in path.parents and path.name != ".gitkeep":
            return True
    return False


def main() -> int:
    violations: list[tuple[str, PurePosixPath]] = []
    for path in tracked_paths():
        if path in FORBIDDEN_EXACT_PATHS:
            violations.append(("credential or session testing document", path))
        if is_environment_file(path) and path not in ALLOWED_ENV_FILES:
            violations.append(("environment file", path))
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            violations.append(("private key material", path))
        if path.name in {"credentials.json", "token.json"}:
            violations.append(("credential export", path))
        if is_generated_artifact(path):
            violations.append(("runtime or generated artifact", path))

    if violations:
        print("Sensitive artifact policy failed. Tracked paths requiring removal:")
        for category, path in sorted(set(violations), key=lambda item: str(item[1])):
            print(f"- {path} ({category})")
        return 1

    print("Sensitive artifact policy passed: no prohibited tracked paths found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
