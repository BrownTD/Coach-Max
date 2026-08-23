#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${repository_root}/scripts/sync-project-item.sh"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

ln -s "${repository_root}/tests/fixtures/gh-project" "${temporary_directory}/gh"
export PATH="${temporary_directory}:${PATH}"
export GH_TOKEN="test-token"
export PROJECT_OWNER="BrownTD"
export PROJECT_NUMBER="7"
export REPOSITORY="BrownTD/Coach-Max"
export MOCK_GH_LOG="${temporary_directory}/gh.log"

run_estimate_case() {
  local estimate="$1" body_file="${temporary_directory}/body-${1}.md" payload
  : > "$MOCK_GH_LOG"
  printf '<!-- coach-max-project -->\n{"Estimate":%s}\n<!-- end-coach-max-project -->\n' \
    "$estimate" > "$body_file"

  "$script" 35 "" "$body_file" > "${temporary_directory}/stdout"
  payload="$(awk -F '\t' '$1 == "GRAPHQL_INPUT" { print $2 }' "$MOCK_GH_LOG")"
  jq -e --argjson expected "$estimate" \
    '.variables.value == $expected and (.variables.value | type) == "number"' <<<"$payload" >/dev/null
}

run_estimate_case 0.75
run_estimate_case 2

grep -q 'types: \[opened, edited, reopened, closed\]' \
  "${repository_root}/.github/workflows/project-automation.yml"
grep -q 'if \[\[ -z "$issue_number" \]\]; then' \
  "${repository_root}/.github/workflows/project-automation.yml"

echo "Passed fractional and integer Project estimate synchronization tests."
