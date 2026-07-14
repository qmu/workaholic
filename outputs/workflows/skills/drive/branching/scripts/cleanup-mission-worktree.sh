#!/bin/sh -eu
# Remove a mission worktree (.worktrees/<slug>/) and its current branch. Unlike
# cleanup-worktree.sh (which force-removes a merged branch worktree), this NEVER
# discards uncommitted work: it refuses a dirty worktree and reports it, so a
# /mission close cannot silently destroy unshipped changes. Idempotent when the
# worktree is already gone.
#
# Usage: cleanup-mission-worktree.sh <slug>
# Output: {"cleaned": true, "worktree_path": "...", "slug": "...", "branch": "...",
#          "worktree_removed": bool, "branch_removed": bool}

set -eu

slug="${1:-}"

if [ -z "$slug" ]; then
  echo '{"error": "slug is required"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
worktree_path="${repo_root}/.worktrees/${slug}"

worktree_removed=false
branch_removed=false
branch=""

if [ -d "$worktree_path" ]; then
  # Never discard uncommitted work — refuse a dirty worktree.
  if [ -n "$(git -C "$worktree_path" status --porcelain 2>/dev/null)" ]; then
    echo '{"error": "worktree has uncommitted changes; not removed", "worktree_path": "'"${worktree_path}"'"}' >&2
    exit 1
  fi
  branch="$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  git worktree remove "$worktree_path" >&2
  worktree_removed=true
fi

git worktree prune >&2

if [ -n "$branch" ] && git show-ref --verify --quiet "refs/heads/${branch}"; then
  git branch -d "$branch" >/dev/null 2>&1 || git branch -D "$branch" >/dev/null 2>&1
  branch_removed=true
fi

cat <<EOF
{"cleaned": true, "worktree_path": "$worktree_path", "slug": "$slug", "branch": "$branch", "worktree_removed": $worktree_removed, "branch_removed": $branch_removed}
EOF
