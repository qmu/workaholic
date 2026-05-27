#!/bin/bash
# Lightweight check for existence of worktrees.
# Usage: bash check-worktrees.sh
# Output: JSON with has_worktrees (boolean), count, work_count
# Unlike list-worktrees.sh, this script does not query GitHub API.

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
count=0
work_count=0
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
      # Match work-*, drive-* (legacy), trip/* (legacy)
      if [[ "$current_branch" == work-* ]] || [[ "$current_branch" == drive-* ]] || [[ "$current_branch" == trip/* ]]; then
        work_count=$((work_count + 1))
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
  echo "{\"has_worktrees\": true, \"count\": ${count}, \"work_count\": ${work_count}}"
else
  echo "{\"has_worktrees\": false, \"count\": 0, \"work_count\": 0}"
fi
