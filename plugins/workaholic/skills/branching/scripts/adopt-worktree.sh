#!/bin/bash
# Adopt an existing branch into a git worktree.
# Usage: bash adopt-worktree.sh <branch-name>
# Output: JSON with worktree_path, branch, and switched_from flag

set -euo pipefail

branch="${1:-}"

if [ -z "$branch" ]; then
  echo '{"error": "branch name is required"}' >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
worktree_path="${repo_root}/.worktrees/${branch}"

# Verify branch exists
if ! git show-ref --verify --quiet "refs/heads/${branch}"; then
  echo '{"error": "branch not found", "branch": "'"${branch}"'"}' >&2
  exit 1
fi

# Check if worktree already exists for this branch
if git worktree list --porcelain | grep -q "worktree ${worktree_path}"; then
  echo '{"error": "worktree already exists", "worktree_path": "'"${worktree_path}"'"}' >&2
  exit 1
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo '{"error": "working tree has uncommitted changes, commit or stash first"}' >&2
  exit 1
fi

switched_from=false
current_branch=$(git branch --show-current)

# If currently on the target branch, switch to main first
if [ "$current_branch" = "$branch" ]; then
  git checkout main
  switched_from=true
fi

mkdir -p "${repo_root}/.worktrees"

# Create worktree using existing branch (no -b flag)
git worktree add "${worktree_path}" "${branch}"

echo '{"worktree_path": "'"${worktree_path}"'", "branch": "'"${branch}"'", "switched_from": '"${switched_from}"'}'
