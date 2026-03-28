#!/bin/bash
# Lightweight check for existence of worktrees (trip and non-trip).
# Usage: bash check-worktrees.sh
# Output: JSON with has_worktrees (boolean), count, trip_count, drive_count
# Unlike list-trip-worktrees.sh, this script does not query GitHub API.

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
count=0
trip_count=0
drive_count=0
current_path=""
current_branch=""

while IFS= read -r line; do
  if [[ "$line" =~ ^worktree\ (.+)$ ]]; then
    current_path="${BASH_REMATCH[1]}"
    current_branch=""
  elif [[ "$line" =~ ^branch\ refs/heads/(.+)$ ]]; then
    current_branch="${BASH_REMATCH[1]}"
  elif [ -z "$line" ] && [ -n "$current_branch" ] && [ -n "$current_path" ]; then
    # Skip main working tree
    if [ "$current_path" != "$repo_root" ]; then
      count=$((count + 1))
      if [[ "$current_branch" == trip/* ]]; then
        trip_count=$((trip_count + 1))
      elif [[ "$current_branch" == drive-* ]]; then
        drive_count=$((drive_count + 1))
      fi
    fi
    current_path=""
    current_branch=""
  elif [ -z "$line" ]; then
    current_path=""
    current_branch=""
  fi
done < <(git worktree list --porcelain && echo "")

if [ "$count" -gt 0 ]; then
  echo "{\"has_worktrees\": true, \"count\": ${count}, \"trip_count\": ${trip_count}, \"drive_count\": ${drive_count}}"
else
  echo "{\"has_worktrees\": false, \"count\": 0, \"trip_count\": 0, \"drive_count\": 0}"
fi
