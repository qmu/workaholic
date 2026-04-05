#!/bin/bash
# Initialize a trip directory structure under .workaholic/trips/
# Usage: bash init-trip.sh <trip-name> [instruction]
# The optional instruction argument is the user's original trip description.
# Output: JSON with trip_path and plan_path

set -euo pipefail

trip_name="${1:-}"
instruction="${2:-}"

if [ -z "$trip_name" ]; then
  echo '{"error": "trip name is required"}' >&2
  exit 1
fi

if ! echo "$trip_name" | grep -qE '^[a-z0-9][a-z0-9-]*[a-z0-9]$'; then
  echo '{"error": "trip name must be lowercase alphanumeric with hyphens, no leading/trailing hyphens"}' >&2
  exit 1
fi

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

trip_path="${root}/.workaholic/trips/${trip_name}"

if [ -d "$trip_path" ]; then
  echo '{"error": "trip directory already exists", "trip_path": "'"$trip_path"'"}' >&2
  exit 1
fi

mkdir -p "${trip_path}/directions" "${trip_path}/models" "${trip_path}/designs" "${trip_path}/reviews" "${trip_path}/rollbacks/reviews"

# Create event log with header
{
  echo '# Trip Event Log'
  echo ''
  echo '| Timestamp | Agent | Event | Target | Impact |'
  echo '| --------- | ----- | ----- | ------ | ------ |'
} > "${trip_path}/event-log.md"

# Create plan.md with initial state
updated_at="$(date -Iseconds)"
plan_file="${trip_path}/plan.md"

# Sanitize instruction for YAML: escape backslashes first, then double quotes
safe_instruction="${instruction//\\/\\\\}"
safe_instruction="${safe_instruction//\"/\\\"}"

# Write plan.md — use printf %s to avoid interpreting escape sequences in content
{
  echo '---'
  printf 'instruction: "%s"\n' "$safe_instruction"
  echo 'phase: planning'
  echo 'step: not-started'
  echo 'iteration: 0'
  printf 'updated_at: %s\n' "$updated_at"
  echo '---'
  echo ''
  echo '# Trip Plan'
  echo ''
  echo '## Initial Idea'
  echo ''
  if [ -n "$instruction" ]; then
    printf '%s\n' "$instruction"
  else
    echo '_(No instruction provided)_'
  fi
  echo ''
  echo '## Plan Amendments'
  echo ''
  echo '## Progress'
} > "$plan_file"

echo '{"trip_path": "'"$trip_path"'", "plan_path": "'"${plan_file}"'"}'
