#!/bin/bash
# List all active worktrees with type detection.
# Usage: bash list-all-worktrees.sh
# Output: JSON with count and worktree details (no GitHub API calls)

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
worktrees_json="[]"
count=0

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
    if [ "$current_path" = "$repo_root" ]; then
      current_path=""
      current_branch=""
      continue
    fi

    # Detect type from branch pattern
    if [[ "$current_branch" == trip/* ]]; then
      wt_type="trip"
      wt_name="${current_branch#trip/}"
    elif [[ "$current_branch" == drive-* ]]; then
      wt_type="drive"
      wt_name="${current_branch}"
    else
      wt_type="other"
      wt_name="${current_branch}"
    fi

    entry="{\"name\":\"${wt_name}\",\"branch\":\"${current_branch}\",\"worktree_path\":\"${current_path}\",\"type\":\"${wt_type}\"}"
    worktrees_json=$(echo "$worktrees_json" | jq --argjson e "$entry" '. + [$e]')
    count=$((count + 1))

    current_path=""
    current_branch=""
  elif [ -z "$line" ]; then
    current_path=""
    current_branch=""
  fi
done < <(git worktree list --porcelain && echo "")

echo "{\"count\":${count},\"worktrees\":${worktrees_json}}"
