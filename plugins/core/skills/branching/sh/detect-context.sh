#!/bin/bash
# Detect development context from current branch pattern.
# Usage: bash detect-context.sh
# Output: JSON with context type, branch, and optional trip_name

set -euo pipefail

branch=$(git branch --show-current 2>/dev/null || echo "")

if [ -z "$branch" ]; then
  echo '{"context": "unknown", "branch": ""}'
  exit 0
fi

# Drive context: branch matches drive-*
if [[ "$branch" == drive-* ]]; then
  echo "{\"context\": \"drive\", \"branch\": \"${branch}\"}"
  exit 0
fi

# Trip context: branch matches trip/*
if [[ "$branch" == trip/* ]]; then
  trip_name="${branch#trip/}"
  # Check if drive-style tickets exist (trip_drive hybrid)
  ticket_count=$(find .workaholic/tickets/todo -name '*.md' 2>/dev/null | wc -l)
  if [ "$ticket_count" -gt 0 ]; then
    echo "{\"context\": \"trip_drive\", \"branch\": \"${branch}\", \"trip_name\": \"${trip_name}\"}"
    exit 0
  fi
  echo "{\"context\": \"trip\", \"branch\": \"${branch}\", \"trip_name\": \"${trip_name}\"}"
  exit 0
fi

# Main/master: unknown context
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  echo "{\"context\": \"unknown\", \"branch\": \"${branch}\"}"
  exit 0
fi

# Other branch: check for trip worktrees
script_dir="$(cd "$(dirname "$0")" && pwd)"
list_script="${script_dir}/../../trip-protocol/sh/list-trip-worktrees.sh"

if [ -f "$list_script" ]; then
  worktree_output=$(bash "$list_script" 2>/dev/null || echo '{"count": 0}')
  count=$(echo "$worktree_output" | jq -r '.count' 2>/dev/null || echo "0")

  if [ "$count" -gt 0 ]; then
    echo "{\"context\": \"trip_worktree\", \"branch\": \"${branch}\"}"
    exit 0
  fi
fi

echo "{\"context\": \"unknown\", \"branch\": \"${branch}\"}"
