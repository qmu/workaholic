#!/bin/sh -eu
# List all active worktrees with type detection.
# Usage: sh list-all-worktrees.sh
# Output: JSON with count and worktree details (no GitHub API calls)

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

    # Detect type from branch pattern
    case "$current_branch" in
      work-*|drive-*|trip/*) wt_type="work" ;;
      *) wt_type="other" ;;
    esac
    # A MISSION worktree is keyed by a descriptive slug DIRECTORY under
    # .worktrees/ (its branch is still work-*), so detect it by the path's
    # basename rather than the branch pattern.
    wt_basename="${current_path##*/}"
    case "$current_path" in
      */.worktrees/*)
        case "$wt_basename" in
          work-*|drive-*|trip-*) : ;;
          *) wt_type="mission" ;;
        esac
        ;;
    esac
    wt_name="${current_branch}"

    entry="{\"name\":\"${wt_name}\",\"branch\":\"${current_branch}\",\"worktree_path\":\"${current_path}\",\"type\":\"${wt_type}\"}"
    worktrees_json=$(printf '%s' "$worktrees_json" | jq --argjson e "$entry" '. + [$e]')
    count=$((count + 1))
  fi

  current_path=""
  current_branch=""
done <<EOF
$wt_list

EOF

echo "{\"count\":${count},\"worktrees\":${worktrees_json}}"
