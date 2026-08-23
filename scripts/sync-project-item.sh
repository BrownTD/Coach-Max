#!/usr/bin/env bash

set -euo pipefail

issue_number="${1:?issue number is required}"
status_value="${2:-}"
body_file="${3:-}"

: "${GH_TOKEN:?GH_TOKEN is required}"
: "${PROJECT_OWNER:?PROJECT_OWNER is required}"
: "${PROJECT_NUMBER:?PROJECT_NUMBER is required}"
: "${REPOSITORY:?REPOSITORY is required}"

if [[ ! "$issue_number" =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid issue number: ${issue_number}" >&2
  exit 2
fi

project_json="$(gh api graphql \
  -f query='query($owner: String!, $number: Int!) {
    user(login: $owner) {
      projectV2(number: $number) {
        id
        fields(first: 100) {
          nodes {
            __typename
            ... on ProjectV2Field { id name dataType }
            ... on ProjectV2SingleSelectField { id name dataType options { id name } }
            ... on ProjectV2IterationField {
              id
              name
              dataType
              configuration { iterations { id title startDate duration } }
            }
          }
        }
      }
    }
  }' \
  -f owner="$PROJECT_OWNER" \
  -F number="$PROJECT_NUMBER")"

project_id="$(jq -r '.data.user.projectV2.id // empty' <<<"$project_json")"
if [[ -z "$project_id" ]]; then
  echo "Unable to resolve user Project ${PROJECT_OWNER}/${PROJECT_NUMBER}." >&2
  exit 1
fi

issue_json="$(gh api "repos/${REPOSITORY}/issues/${issue_number}")"
issue_node_id="$(jq -r '.node_id' <<<"$issue_json")"
issue_url="$(jq -r '.html_url' <<<"$issue_json")"

item_query="$(gh api graphql \
  -f query='query($issue: ID!) {
    node(id: $issue) {
      ... on Issue {
        projectItems(first: 100) { nodes { id project { id } } }
      }
    }
  }' \
  -f issue="$issue_node_id")"

item_id="$(jq -r --arg project "$project_id" '.data.node.projectItems.nodes[]? | select(.project.id == $project) | .id' <<<"$item_query" | head -n 1)"

if [[ -z "$item_id" ]]; then
  add_result="$(gh api graphql \
    -f query='mutation($project: ID!, $content: ID!) {
      addProjectV2ItemById(input: { projectId: $project, contentId: $content }) {
        item { id }
      }
    }' \
    -f project="$project_id" \
    -f content="$issue_node_id")"
  item_id="$(jq -r '.data.addProjectV2ItemById.item.id // empty' <<<"$add_result")"
fi

if [[ -z "$item_id" ]]; then
  echo "Unable to resolve or create the Project item for ${issue_url}." >&2
  exit 1
fi

field_id() {
  local field_name="$1"
  jq -r --arg name "$field_name" '.data.user.projectV2.fields.nodes[]? | select(.name == $name) | .id' <<<"$project_json" | head -n 1
}

set_text_field() {
  local name="$1" value="$2" id
  id="$(field_id "$name")"
  [[ -n "$id" ]] || { echo "Missing Project field: ${name}" >&2; return 1; }
  gh api graphql --silent \
    -f query='mutation($project: ID!, $item: ID!, $field: ID!, $value: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $project, itemId: $item, fieldId: $field, value: { text: $value }
      }) { projectV2Item { id } }
    }' \
    -f project="$project_id" -f item="$item_id" -f field="$id" -f value="$value"
}

set_single_select_field() {
  local name="$1" value="$2" id option_id
  id="$(field_id "$name")"
  [[ -n "$id" ]] || { echo "Missing Project field: ${name}" >&2; return 1; }
  option_id="$(jq -r --arg name "$name" --arg value "$value" '
    .data.user.projectV2.fields.nodes[]?
    | select(.name == $name)
    | .options[]?
    | select(.name == $value)
    | .id' <<<"$project_json" | head -n 1)"
  [[ -n "$option_id" ]] || { echo "Missing option '${value}' in Project field '${name}'." >&2; return 1; }
  gh api graphql --silent \
    -f query='mutation($project: ID!, $item: ID!, $field: ID!, $value: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $project, itemId: $item, fieldId: $field,
        value: { singleSelectOptionId: $value }
      }) { projectV2Item { id } }
    }' \
    -f project="$project_id" -f item="$item_id" -f field="$id" -f value="$option_id"
}

set_number_field() {
  local name="$1" value="$2" id
  id="$(field_id "$name")"
  [[ -n "$id" ]] || { echo "Missing Project field: ${name}" >&2; return 1; }
  gh api graphql --silent \
    -f query='mutation($project: ID!, $item: ID!, $field: ID!, $value: Float!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $project, itemId: $item, fieldId: $field, value: { number: $value }
      }) { projectV2Item { id } }
    }' \
    -f project="$project_id" -f item="$item_id" -f field="$id" -F value="$value"
}

set_date_field() {
  local name="$1" value="$2" id
  id="$(field_id "$name")"
  [[ -n "$id" ]] || { echo "Missing Project field: ${name}" >&2; return 1; }
  gh api graphql --silent \
    -f query='mutation($project: ID!, $item: ID!, $field: ID!, $value: Date!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $project, itemId: $item, fieldId: $field, value: { date: $value }
      }) { projectV2Item { id } }
    }' \
    -f project="$project_id" -f item="$item_id" -f field="$id" -f value="$value"
}

set_iteration_field() {
  local name="$1" value="$2" id iteration_id
  id="$(field_id "$name")"
  [[ -n "$id" ]] || { echo "Missing Project field: ${name}" >&2; return 1; }
  iteration_id="$(jq -r --arg name "$name" --arg value "$value" '
    .data.user.projectV2.fields.nodes[]?
    | select(.name == $name)
    | .configuration.iterations[]?
    | select(.title == $value)
    | .id' <<<"$project_json" | head -n 1)"
  [[ -n "$iteration_id" ]] || { echo "Missing iteration '${value}' in Project field '${name}'." >&2; return 1; }
  gh api graphql --silent \
    -f query='mutation($project: ID!, $item: ID!, $field: ID!, $value: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $project, itemId: $item, fieldId: $field, value: { iterationId: $value }
      }) { projectV2Item { id } }
    }' \
    -f project="$project_id" -f item="$item_id" -f field="$id" -f value="$iteration_id"
}

extract_heading_value() {
  local heading="$1"
  [[ -n "$body_file" && -f "$body_file" ]] || return 0
  awk -v target="### ${heading}" '
    $0 == target { capture = 1; next }
    capture && /^### / { exit }
    capture && $0 !~ /^[[:space:]]*$/ { print; exit }
  ' "$body_file"
}

metadata_json=""
if [[ -n "$body_file" && -f "$body_file" ]]; then
  metadata_json="$(awk '
    /<!-- coach-max-project -->/ { capture = 1; next }
    /<!-- end-coach-max-project -->/ { capture = 0 }
    capture { print }
  ' "$body_file")"
fi

metadata_value() {
  local name="$1" value=""
  if [[ -n "$metadata_json" ]] && jq -e . >/dev/null 2>&1 <<<"$metadata_json"; then
    value="$(jq -r --arg name "$name" '.[$name] // empty' <<<"$metadata_json")"
  fi
  if [[ -z "$value" ]]; then
    value="$(extract_heading_value "$name")"
  fi
  printf '%s' "$value"
}

set_text_field "Ticket Key" "CMX-${issue_number}"
if [[ -n "$status_value" ]]; then
  set_single_select_field "Status" "$status_value"
fi

issue_type="$(metadata_value "Issue Type")"
if [[ -z "$issue_type" ]]; then
  # Backward compatibility for issues generated before the Project field was
  # standardized as "Issue Type".
  issue_type="$(metadata_value "Type")"
fi
if [[ -n "$issue_type" && "$issue_type" != "Not set" ]]; then
  set_single_select_field "Issue Type" "$issue_type"
fi

for name in "Phase" "Workstream" "Priority" "Release" "Risk"; do
  value="$(metadata_value "$name")"
  if [[ -n "$value" && "$value" != "Not set" ]]; then
    set_single_select_field "$name" "$value"
  fi
done

estimate="$(metadata_value "Estimate")"
if [[ -n "$estimate" && "$estimate" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  set_number_field "Estimate" "$estimate"
fi

for name in "Start Date" "Target Date"; do
  value="$(metadata_value "$name")"
  if [[ -n "$value" && "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    set_date_field "$name" "$value"
  fi
done

iteration="$(metadata_value "Iteration")"
if [[ -n "$iteration" && "$iteration" != "Not set" ]]; then
  set_iteration_field "Iteration" "$iteration"
fi

echo "Synchronized CMX-${issue_number} to Project ${PROJECT_OWNER}/${PROJECT_NUMBER} as '${status_value}'."
