#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: INFISICAL_PROJECT_ID=<id> $0 <development|staging|production> <command> [args...]" >&2
}

if [[ $# -lt 2 ]]; then
  usage
  exit 2
fi

environment_name="$1"
shift

case "$environment_name" in
  development) environment_slug="dev" ;;
  staging) environment_slug="staging" ;;
  production) environment_slug="prod" ;;
  *)
    echo "Unsupported Coach Max environment: ${environment_name}" >&2
    usage
    exit 2
    ;;
esac

: "${INFISICAL_PROJECT_ID:?INFISICAL_PROJECT_ID is required and is not a secret}"

if ! command -v infisical >/dev/null 2>&1; then
  echo "Infisical CLI is required; see docs/SECRETS_MANAGEMENT.md." >&2
  exit 127
fi

export APP_ENV="$environment_name"
export INFISICAL_DISABLE_UPDATE_CHECK=true

# Authentication must already exist in the caller's environment or local CLI
# session. Never pass a token on the command line or export secrets to a file.
exec infisical run \
  --projectId="$INFISICAL_PROJECT_ID" \
  --env="$environment_slug" \
  --path="/" \
  -- "$@"
