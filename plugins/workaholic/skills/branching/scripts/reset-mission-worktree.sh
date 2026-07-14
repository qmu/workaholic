#!/bin/sh -eu
# Reset a mission worktree for its next batch after a merge. A mission worktree
# PERSISTS across many branches (it is removed only at /mission close); after the
# current branch merges, this cuts a FRESH work-YYYYMMDD-HHMMSS branch off the
# base (default main) inside the same worktree, so it is immediately drive-ready
# again. Never discards uncommitted work (refuses a dirty worktree).
#
# Usage: reset-mission-worktree.sh <slug> [base-branch]
# Output: {"worktree_path": "...", "branch": "work-YYYYMMDD-HHMMSS", "slug": "...", "base": "..."}

set -eu

slug="${1:-}"
base="${2:-main}"

if [ -z "$slug" ]; then
  echo '{"error": "slug is required"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
worktree_path="${repo_root}/.worktrees/${slug}"

if [ ! -d "$worktree_path" ]; then
  echo '{"error": "mission worktree not found", "worktree_path": "'"${worktree_path}"'"}' >&2
  exit 1
fi

# Never discard uncommitted work — refuse a dirty worktree.
if [ -n "$(git -C "$worktree_path" status --porcelain 2>/dev/null)" ]; then
  echo '{"error": "worktree has uncommitted changes; not reset", "worktree_path": "'"${worktree_path}"'"}' >&2
  exit 1
fi

branch="work-$(date +%Y%m%d-%H%M%S)"
if git show-ref --verify --quiet "refs/heads/${branch}"; then
  echo '{"error": "branch already exists (retry in a moment)", "branch": "'"${branch}"'"}' >&2
  exit 1
fi

# Cut the fresh branch from the base's tip WITHOUT checking out the base itself
# (base is checked out in the main tree; `checkout -b <new> <base>` only uses it
# as a start point). Chatter goes to stderr so stdout carries only the JSON.
git -C "$worktree_path" checkout -b "$branch" "$base" >&2

echo '{"worktree_path": "'"${worktree_path}"'", "branch": "'"${branch}"'", "slug": "'"${slug}"'", "base": "'"${base}"'"}'
