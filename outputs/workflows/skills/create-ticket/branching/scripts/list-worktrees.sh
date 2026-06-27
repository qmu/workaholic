#!/bin/sh -eu
# List active work worktrees with metadata (branch, path, PR status).
# Usage: sh list-worktrees.sh
# Output: JSON with count and worktree details
# Matches work-*, drive-* (legacy), and trip/* (legacy) branches.

set -eu

repo_root="$(git rev-parse --show-toplevel)"
worktrees_json="[]"
count=0

current_path=""
current_branch=""

# Here-doc keeps the loop in the current shell so worktrees_json/count persist
# (POSIX has no `< <(...)`).
wt_list="$(git worktree list --porcelain && echo "")"

while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      current_path="${line#worktree }"
      current_branch=""
      continue
      ;;
    "branch refs/heads/"*)
      current_branch="${line#branch refs/heads/}"
      continue
      ;;
    "") : ;;
    *) continue ;;
  esac

  # Blank line: a record boundary.
  if [ -n "$current_branch" ] && [ -n "$current_path" ]; then
    # Skip main working tree
    if [ "$current_path" = "$repo_root" ]; then
      current_path=""
      current_branch=""
      continue
    fi

    # Match work-*, drive-* (legacy), trip/* (legacy)
    case "$current_branch" in
      work-*|drive-*|trip/*)
        # Check for existing PR
        pr_info=$(gh pr list --head "$current_branch" --state open --json number,url --jq '.[0]' 2>/dev/null || echo "")

        if [ -n "$pr_info" ] && [ "$pr_info" != "null" ]; then
          pr_number=$(printf '%s' "$pr_info" | jq -r '.number')
          pr_url=$(printf '%s' "$pr_info" | jq -r '.url')
          entry="{\"name\":\"${current_branch}\",\"branch\":\"${current_branch}\",\"worktree_path\":\"${current_path}\",\"has_pr\":true,\"pr_number\":${pr_number},\"pr_url\":\"${pr_url}\"}"
        else
          entry="{\"name\":\"${current_branch}\",\"branch\":\"${current_branch}\",\"worktree_path\":\"${current_path}\",\"has_pr\":false}"
        fi

        worktrees_json=$(printf '%s' "$worktrees_json" | jq --argjson e "$entry" '. + [$e]')
        count=$((count + 1))
        ;;
    esac
  fi

  current_path=""
  current_branch=""
done <<EOF
$wt_list
EOF

echo "{\"count\":${count},\"worktrees\":${worktrees_json}}"
