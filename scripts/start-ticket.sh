#!/usr/bin/env bash

set -euo pipefail

ticket="${1:-}"
base_branch="${2:-main}"

if [[ ! "$ticket" =~ ^CMX-([1-9][0-9]*)$ ]]; then
  echo "Usage: $0 CMX-<issue-number> [base-branch]" >&2
  exit 2
fi

issue_number="${BASH_REMATCH[1]}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "The worktree must be clean before starting ${ticket}." >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/${ticket}"; then
  echo "Local branch ${ticket} already exists." >&2
  exit 1
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  issue_state="$(gh issue view "$issue_number" --json state --jq .state 2>/dev/null || true)"
  if [[ "$issue_state" != "OPEN" ]]; then
    echo "GitHub issue #${issue_number} does not exist or is not open." >&2
    exit 1
  fi
else
  echo "Warning: GitHub CLI is unavailable or unauthenticated; skipping remote issue validation." >&2
fi

git fetch origin "$base_branch"
git switch "$base_branch"
git pull --ff-only origin "$base_branch"
git switch -c "$ticket"
git config core.hooksPath .githooks

echo "Created ${ticket} from ${base_branch}."
echo "Commit subjects must begin with: ${ticket}: "
