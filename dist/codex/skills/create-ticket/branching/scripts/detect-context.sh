#!/bin/bash
# Detect development context from current branch pattern.
# Usage: bash detect-context.sh
# Output: JSON with context type, branch, and optional mode/trip_name

set -euo pipefail

branch=$(git branch --show-current 2>/dev/null || echo "")
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

if [ -z "$branch" ]; then
  echo '{"context": "unknown", "branch": ""}'
  exit 0
fi

# Detect mode from workspace artifacts
detect_mode() {
  local trips_dir="${root}/.workaholic/trips"
  local todo_dir="${root}/.workaholic/tickets/todo"
  local has_trips=false
  local has_tickets=false

  if [ -d "$trips_dir" ]; then
    trip_dirs=$(find "$trips_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    if [ "$trip_dirs" -gt 0 ]; then
      has_trips=true
    fi
  fi

  ticket_count=$(find "$todo_dir" -name '*.md' 2>/dev/null | wc -l)
  if [ "$ticket_count" -gt 0 ]; then
    has_tickets=true
  fi

  if $has_trips && $has_tickets; then
    echo "hybrid"
  elif $has_trips; then
    echo "trip"
  elif $has_tickets; then
    echo "drive"
  else
    echo "drive"
  fi
}

# Work context: branch matches work-*
if [[ "$branch" == work-* ]]; then
  mode=$(detect_mode)
  echo "{\"context\": \"work\", \"branch\": \"${branch}\", \"mode\": \"${mode}\"}"
  exit 0
fi

# Backward compat: drive-* branches map to work context with drive mode
if [[ "$branch" == drive-* ]]; then
  echo "{\"context\": \"work\", \"branch\": \"${branch}\", \"mode\": \"drive\"}"
  exit 0
fi

# Backward compat: trip/* branches map to work context with trip/hybrid mode
if [[ "$branch" == trip/* ]]; then
  trip_name="${branch#trip/}"
  mode=$(detect_mode)
  if [ "$mode" = "drive" ]; then
    mode="trip"
  fi
  echo "{\"context\": \"work\", \"branch\": \"${branch}\", \"mode\": \"${mode}\", \"trip_name\": \"${trip_name}\"}"
  exit 0
fi

# Main/master: unknown context
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  echo "{\"context\": \"unknown\", \"branch\": \"${branch}\"}"
  exit 0
fi

# Other branch: check for worktrees
script_dir="$(cd "$(dirname "$0")" && pwd)"
list_script="${script_dir}/list-worktrees.sh"

if [ -f "$list_script" ]; then
  worktree_output=$(bash "$list_script" 2>/dev/null || echo '{"count": 0}')
  count=$(echo "$worktree_output" | jq -r '.count' 2>/dev/null || echo "0")

  if [ "$count" -gt 0 ]; then
    echo "{\"context\": \"worktree\", \"branch\": \"${branch}\"}"
    exit 0
  fi
fi

echo "{\"context\": \"unknown\", \"branch\": \"${branch}\"}"
