#!/bin/bash
# Lightweight check for existence of trip worktrees.
# Usage: bash check-worktrees.sh
# Output: JSON with has_worktrees (boolean) and count (number)
# Unlike list-trip-worktrees.sh, this script does not query GitHub API.

set -euo pipefail

count=0
current_branch=""

while IFS= read -r line; do
  if [[ "$line" =~ ^branch\ refs/heads/(trip/.+)$ ]]; then
    current_branch="${BASH_REMATCH[1]}"
  elif [ -z "$line" ] && [ -n "$current_branch" ]; then
    count=$((count + 1))
    current_branch=""
  elif [ -z "$line" ]; then
    current_branch=""
  fi
done < <(git worktree list --porcelain && echo "")

if [ "$count" -gt 0 ]; then
  echo "{\"has_worktrees\": true, \"count\": ${count}}"
else
  echo "{\"has_worktrees\": false, \"count\": 0}"
fi
