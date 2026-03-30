#!/bin/bash
# Ensure git worktree readiness and create an isolated worktree for a trip session.
# Usage: bash ensure-worktree.sh <trip-name>
# Output: JSON with worktree_path and branch

set -euo pipefail

trip_name="${1:-}"

if [ -z "$trip_name" ]; then
  echo '{"error": "trip name is required"}' >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
branch="trip/${trip_name}"
worktree_path="${repo_root}/.worktrees/${trip_name}"

if git worktree list --porcelain | grep -q "worktree ${worktree_path}"; then
  echo '{"error": "worktree already exists", "worktree_path": "'"${worktree_path}"'"}' >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/${branch}"; then
  echo '{"error": "branch already exists", "branch": "'"${branch}"'"}' >&2
  exit 1
fi

mkdir -p "${repo_root}/.worktrees"

git worktree add -b "${branch}" "${worktree_path}" HEAD

echo '{"worktree_path": "'"${worktree_path}"'", "branch": "'"${branch}"'"}'
