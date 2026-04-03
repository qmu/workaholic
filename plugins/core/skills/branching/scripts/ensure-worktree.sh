#!/bin/bash
# Ensure git worktree readiness and create an isolated worktree.
# Usage: bash ensure-worktree.sh <branch-name>
# Output: JSON with worktree_path and branch

set -euo pipefail

branch_name="${1:-}"

if [ -z "$branch_name" ]; then
  echo '{"error": "branch name is required"}' >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
worktree_path="${repo_root}/.worktrees/${branch_name}"

if git worktree list --porcelain | grep -q "worktree ${worktree_path}"; then
  echo '{"error": "worktree already exists", "worktree_path": "'"${worktree_path}"'"}' >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
  echo '{"error": "branch already exists", "branch": "'"${branch_name}"'"}' >&2
  exit 1
fi

mkdir -p "${repo_root}/.worktrees"

git worktree add -b "${branch_name}" "${worktree_path}" HEAD

echo '{"worktree_path": "'"${worktree_path}"'", "branch": "'"${branch_name}"'"}'
