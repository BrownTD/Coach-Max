#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${repository_root}/scripts/sync-issue-hierarchy.sh"
fixture_path="${repository_root}/tests/fixtures"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

export PATH="${fixture_path}:${PATH}"
export GH_TOKEN="test-token"
export REPOSITORY="BrownTD/Coach-Max"
export MOCK_GH_LOG="${temporary_directory}/gh.log"
export MOCK_CHILD_NUMBER=23
export MOCK_PARENT_NUMBER=22

passed=0

reset_case() {
  : > "$MOCK_GH_LOG"
  unset MOCK_CURRENT_PARENT_NUMBER MOCK_PARENT_TYPE MOCK_CHILD_IS_PR MOCK_PARENT_IS_PR MOCK_ADD_FAIL
}

write_body() {
  local issue_type="$1" parent_value="${2:-}"
  if [[ -n "$parent_value" ]]; then
    printf '<!-- coach-max-project -->\n{"Issue Type":"%s","Parent Issue":%s}\n<!-- end-coach-max-project -->\n' \
      "$issue_type" "$parent_value" > "${temporary_directory}/body.md"
  else
    printf '<!-- coach-max-project -->\n{"Issue Type":"%s"}\n<!-- end-coach-max-project -->\n' \
      "$issue_type" > "${temporary_directory}/body.md"
  fi
}

write_heading_body() {
  printf '### Issue Type\n\nTask\n\n### Parent Issue\n\n22\n' > "${temporary_directory}/body.md"
}

expect_success() {
  local name="$1"
  shift
  if "$@" > "${temporary_directory}/stdout" 2> "${temporary_directory}/stderr"; then
    passed=$((passed + 1))
  else
    echo "FAIL: ${name}" >&2
    sed -n '1,120p' "${temporary_directory}/stderr" >&2
    exit 1
  fi
}

expect_failure() {
  local name="$1"
  shift
  if "$@" > "${temporary_directory}/stdout" 2> "${temporary_directory}/stderr"; then
    echo "FAIL: ${name} unexpectedly succeeded" >&2
    exit 1
  fi
  passed=$((passed + 1))
}

reset_case
write_body Task
expect_success "missing parent is a no-op" "$script" 23 "${temporary_directory}/body.md"
[[ ! -s "$MOCK_GH_LOG" ]]

reset_case
write_heading_body
expect_success "Issue Form headings are supported" "$script" 23 "${temporary_directory}/body.md"
grep -q $'/issues/22/sub_issues\t' "$MOCK_GH_LOG"

reset_case
write_body Task '"invalid"'
expect_failure "invalid parent is rejected" "$script" 23 "${temporary_directory}/body.md"

reset_case
write_body Task 23
expect_failure "self-parenting is rejected" "$script" 23 "${temporary_directory}/body.md"

reset_case
write_body Feature 22
export MOCK_PARENT_TYPE=Epic
expect_success "Feature links to Epic" "$script" 23 "${temporary_directory}/body.md"
grep -q $'/issues/22/sub_issues\t' "$MOCK_GH_LOG"
grep -q 'sub_issue_id=100' "$MOCK_GH_LOG"
grep -q 'replace_parent=true' "$MOCK_GH_LOG"

reset_case
write_body Feature 22
export MOCK_PARENT_TYPE=Feature
expect_failure "Feature cannot link to Feature" "$script" 23 "${temporary_directory}/body.md"

reset_case
write_body Task 22
export MOCK_PARENT_TYPE=Feature
export MOCK_CURRENT_PARENT_NUMBER=22
expect_success "existing relationship is idempotent" "$script" 23 "${temporary_directory}/body.md"
grep -q $'/issues/23/parent\t' "$MOCK_GH_LOG"
! grep -q '/issues/22/sub_issues' "$MOCK_GH_LOG"

reset_case
write_body Bug 22
export MOCK_PARENT_TYPE=Feature
export MOCK_CURRENT_PARENT_NUMBER=21
expect_success "existing parent can be replaced" "$script" 23 "${temporary_directory}/body.md"
grep -q '/issues/22/sub_issues' "$MOCK_GH_LOG"

reset_case
write_body Task 22
export MOCK_CHILD_IS_PR=true
expect_failure "pull request child is rejected" "$script" 23 "${temporary_directory}/body.md"

reset_case
write_body Task 22
export MOCK_PARENT_IS_PR=true
expect_failure "pull request parent is rejected" "$script" 23 "${temporary_directory}/body.md"

reset_case
write_body Epic 22
expect_failure "Epic cannot declare a parent" "$script" 23 "${temporary_directory}/body.md"

reset_case
write_body Task 22
export MOCK_PARENT_TYPE=Epic
export MOCK_ADD_FAIL=true
expect_failure "API failure is surfaced" "$script" 23 "${temporary_directory}/body.md"

printf 'Passed %s hierarchy synchronization tests.\n' "$passed"
