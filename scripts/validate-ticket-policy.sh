#!/usr/bin/env bash

set -euo pipefail

branch="${1:?branch is required}"
pr_title="${2:?pull-request title is required}"
pr_body_file="${3:?pull-request body file is required}"
commit_subjects_file="${4:?commit subjects file is required}"

if [[ ! "$branch" =~ ^CMX-([1-9][0-9]*)$ ]]; then
  echo "Branch '${branch}' must exactly match CMX-<issue-number>." >&2
  exit 1
fi

issue_number="${BASH_REMATCH[1]}"
expected_prefix="${branch}: "

if [[ "$pr_title" != "$expected_prefix"* ]] || [[ "$pr_title" == "$expected_prefix" ]]; then
  echo "PR title must begin with '${expected_prefix}'." >&2
  exit 1
fi

closing_pattern="(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved)[[:space:]]*:?[[:space:]]*#${issue_number}([^0-9]|$)"
if ! grep -Eiq "$closing_pattern" "$pr_body_file"; then
  echo "PR body must close issue #${issue_number}, for example: Closes #${issue_number}." >&2
  exit 1
fi

commit_count=0
while IFS= read -r subject || [[ -n "$subject" ]]; do
  [[ -z "$subject" ]] && continue
  commit_count=$((commit_count + 1))
  if [[ "$subject" != "$expected_prefix"* ]] || [[ "$subject" == "$expected_prefix" ]]; then
    echo "Commit subject '${subject}' must begin with '${expected_prefix}'." >&2
    exit 1
  fi
done < "$commit_subjects_file"

if (( commit_count == 0 )); then
  echo "The pull request contains no commits to validate." >&2
  exit 1
fi

printf 'Validated %s against issue #%s with %s commit(s).\n' "$branch" "$issue_number" "$commit_count"
