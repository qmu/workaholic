#!/bin/sh -eu
# Lightweight check for existence of worktrees.
# Usage: sh check-worktrees.sh
# Output: JSON with has_worktrees (boolean), count, work_count
# Unlike list-worktrees.sh, this script does not query GitHub API.

set -eu

repo_root="$(git rev-parse --show-toplevel)"
count=0
work_count=0
current_path=""
current_branch=""

# Count a completed porcelain block and reset the block state. Called on each
# blank separator line AND once after the loop: `$( )` strips the output's
# trailing newlines, so the last block never gets its blank separator and must
# be flushed explicitly (relying on a trailing blank line surviving the capture
# is what silently dropped the last worktree).
flush_block() {
  if [ -n "$current_branch" ] && [ -n "$current_path" ]; then
    # Skip main working tree
    if [ "$current_path" != "$repo_root" ]; then
      count=$((count + 1))
      # Match work-*, drive-* (legacy), trip/* (legacy)
      case "$current_branch" in
        work-*|drive-*|trip/*) work_count=$((work_count + 1)) ;;
      esac
    fi
  fi
  current_path=""
  current_branch=""
}

# Feed the porcelain output via a here-doc so the while loop runs in the current
# shell (POSIX has no `< <(...)`; a pipe would lose count/work_count to a subshell).
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
      flush_block
      ;;
  esac
done <<EOF
$wt_list
EOF
flush_block

if [ "$count" -gt 0 ]; then
  echo "{\"has_worktrees\": true, \"count\": ${count}, \"work_count\": ${work_count}}"
else
  echo "{\"has_worktrees\": false, \"count\": 0, \"work_count\": 0}"
fi
