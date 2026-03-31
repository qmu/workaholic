#!/bin/bash
# List active trip worktrees with metadata (branch, path, PR status).
# Usage: bash list-trip-worktrees.sh
# Output: JSON with count and worktree details

set -euo pipefail

worktrees_json="[]"
count=0

# Parse porcelain output for trip branches
current_path=""
current_branch=""

while IFS= read -r line; do
  if [[ "$line" =~ ^worktree\ (.+)$ ]]; then
    current_path="${BASH_REMATCH[1]}"
    current_branch=""
  elif [[ "$line" =~ ^branch\ refs/heads/(trip/.+)$ ]]; then
    current_branch="${BASH_REMATCH[1]}"
  elif [ -z "$line" ] && [ -n "$current_branch" ] && [ -n "$current_path" ]; then
    trip_name="${current_branch#trip/}"

    # Check for existing PR
    pr_info=$(gh pr list --head "$current_branch" --state open --json number,url --jq '.[0]' 2>/dev/null || echo "")

    if [ -n "$pr_info" ] && [ "$pr_info" != "null" ]; then
      pr_number=$(echo "$pr_info" | jq -r '.number')
      pr_url=$(echo "$pr_info" | jq -r '.url')
      entry="{\"trip_name\":\"${trip_name}\",\"branch\":\"${current_branch}\",\"worktree_path\":\"${current_path}\",\"has_pr\":true,\"pr_number\":${pr_number},\"pr_url\":\"${pr_url}\"}"
    else
      entry="{\"trip_name\":\"${trip_name}\",\"branch\":\"${current_branch}\",\"worktree_path\":\"${current_path}\",\"has_pr\":false}"
    fi

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
