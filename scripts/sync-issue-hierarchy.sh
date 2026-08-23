#!/usr/bin/env bash

set -euo pipefail

issue_number="${1:?issue number is required}"
body_file="${2:?issue body file is required}"

: "${GH_TOKEN:?GH_TOKEN is required}"
: "${REPOSITORY:?REPOSITORY is required}"

if [[ ! "$issue_number" =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid issue number: ${issue_number}" >&2
  exit 2
fi

if [[ ! -f "$body_file" ]]; then
  echo "Issue body file does not exist: ${body_file}" >&2
  exit 2
fi

extract_metadata() {
  awk '
    /<!-- coach-max-project -->/ { capture = 1; next }
    /<!-- end-coach-max-project -->/ { capture = 0 }
    capture { print }
  '
}

extract_heading_value() {
  local heading="$1"
  awk -v target="### ${heading}" '
    $0 == target { capture = 1; next }
    capture && /^### / { exit }
    capture && $0 !~ /^[[:space:]]*$/ { print; exit }
  '
}

metadata_value() {
  local metadata_json="$1" body="$2" name="$3" value=""
  if [[ -n "$metadata_json" ]]; then
    value="$(jq -r --arg name "$name" '.[$name] // empty' <<<"$metadata_json")"
  fi
  if [[ -z "$value" ]]; then
    value="$(extract_heading_value "$name" <<<"$body")"
  fi
  printf '%s' "$value"
}

issue_body="$(<"$body_file")"
metadata_json="$(extract_metadata <<<"$issue_body")"

if [[ -n "$metadata_json" ]] && ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"$metadata_json"; then
  echo "CMX-${issue_number} contains invalid coach-max-project metadata." >&2
  exit 2
fi

parent_issue="$(metadata_value "$metadata_json" "$issue_body" "Parent Issue")"
case "$parent_issue" in
  ""|"Not set"|"_No response_")
    echo "CMX-${issue_number} has no Parent Issue metadata; hierarchy synchronization skipped."
    exit 0
    ;;
esac

parent_issue="${parent_issue#\#}"
if [[ ! "$parent_issue" =~ ^[1-9][0-9]*$ ]]; then
  echo "Parent Issue for CMX-${issue_number} must be a positive issue number, not '${parent_issue}'." >&2
  exit 2
fi

if [[ "$parent_issue" == "$issue_number" ]]; then
  echo "CMX-${issue_number} cannot be its own parent." >&2
  exit 2
fi

child_type="$(metadata_value "$metadata_json" "$issue_body" "Issue Type")"
if [[ -z "$child_type" ]]; then
  child_type="$(metadata_value "$metadata_json" "$issue_body" "Type")"
fi
if [[ -z "$child_type" || "$child_type" == "Not set" || "$child_type" == "_No response_" ]]; then
  echo "CMX-${issue_number} must define Issue Type before it can be linked to a parent." >&2
  exit 2
fi
if [[ "$child_type" == "Epic" ]]; then
  echo "Epic CMX-${issue_number} must remain a hierarchy root and cannot declare Parent Issue." >&2
  exit 2
fi

issue_json="$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "repos/${REPOSITORY}/issues/${issue_number}")"
if jq -e 'has("pull_request")' >/dev/null <<<"$issue_json"; then
  echo "CMX-${issue_number} resolves to a pull request, not an issue." >&2
  exit 2
fi
child_database_id="$(jq -r '.id // empty' <<<"$issue_json")"
if [[ ! "$child_database_id" =~ ^[1-9][0-9]*$ ]]; then
  echo "Unable to resolve the database ID for CMX-${issue_number}." >&2
  exit 1
fi

parent_json="$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "repos/${REPOSITORY}/issues/${parent_issue}")"
if jq -e 'has("pull_request")' >/dev/null <<<"$parent_json"; then
  echo "Parent #${parent_issue} resolves to a pull request, not an issue." >&2
  exit 2
fi

parent_body="$(jq -r '.body // ""' <<<"$parent_json")"
parent_metadata="$(extract_metadata <<<"$parent_body")"
if [[ -n "$parent_metadata" ]] && ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"$parent_metadata"; then
  echo "Parent #${parent_issue} contains invalid coach-max-project metadata." >&2
  exit 2
fi
parent_type="$(metadata_value "$parent_metadata" "$parent_body" "Issue Type")"
if [[ -z "$parent_type" ]]; then
  parent_type="$(metadata_value "$parent_metadata" "$parent_body" "Type")"
fi

if [[ "$child_type" == "Feature" ]]; then
  if [[ "$parent_type" != "Epic" ]]; then
    echo "Feature CMX-${issue_number} must have an Epic parent; #${parent_issue} is '${parent_type:-Not set}'." >&2
    exit 2
  fi
elif [[ "$parent_type" != "Epic" && "$parent_type" != "Feature" ]]; then
  echo "CMX-${issue_number} must have an Epic or Feature parent; #${parent_issue} is '${parent_type:-Not set}'." >&2
  exit 2
fi

current_parent=""
if current_parent_json="$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "repos/${REPOSITORY}/issues/${issue_number}/parent" 2>/dev/null)"; then
  current_parent="$(jq -r '.number // empty' <<<"$current_parent_json")"
fi

if [[ "$current_parent" == "$parent_issue" ]]; then
  echo "CMX-${issue_number} is already a sub-issue of CMX-${parent_issue}."
  exit 0
fi

if gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "repos/${REPOSITORY}/issues/${parent_issue}/sub_issues" \
  --method POST \
  --silent \
  -F sub_issue_id="$child_database_id" \
  -F replace_parent=true; then
  if [[ -n "$current_parent" ]]; then
    echo "Moved CMX-${issue_number} from parent CMX-${current_parent} to CMX-${parent_issue}."
  else
    echo "Linked CMX-${issue_number} as a sub-issue of CMX-${parent_issue}."
  fi
  exit 0
fi

# A concurrent workflow may have created the relationship after the first read.
if current_parent_json="$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "repos/${REPOSITORY}/issues/${issue_number}/parent" 2>/dev/null)"; then
  current_parent="$(jq -r '.number // empty' <<<"$current_parent_json")"
fi
if [[ "$current_parent" == "$parent_issue" ]]; then
  echo "CMX-${issue_number} was concurrently linked to CMX-${parent_issue}; no further action is required."
  exit 0
fi

echo "Unable to link CMX-${issue_number} to parent CMX-${parent_issue}." >&2
exit 1
