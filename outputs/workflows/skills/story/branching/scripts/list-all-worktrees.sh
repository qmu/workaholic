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

# Record a completed porcelain block and reset the block state. Called on each
# blank separator line AND once after the loop: `$( )` strips the output's
# trailing newlines, so the last block never gets its blank separator and must
# be flushed explicitly (relying on a trailing blank line surviving the capture
# is what silently dropped the last worktree in the sibling scripts).
flush_record() {
  if [ -n "$current_branch" ] && [ -n "$current_path" ]; then
    # Skip main working tree
    if [ "$current_path" != "$repo_root" ]; then
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
  fi
  current_path=""
  current_branch=""
}

# Here-doc keeps the loop in the current shell so worktrees_json/count persist
# (POSIX has no `< <(...)`).
wt_list="$(git worktree list --porcelain)"

while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      current_path="${line#worktree }"
      current_branch=""
      ;;
    "branch refs/heads/"*)
      current_branch="${line#branch refs/heads/}"
      ;;
    "")
      flush_record
      ;;
  esac
done <<EOF
$wt_list
EOF
flush_record

echo "{\"count\":${count},\"worktrees\":${worktrees_json}}"
