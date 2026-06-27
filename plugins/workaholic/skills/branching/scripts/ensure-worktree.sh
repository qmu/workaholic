#!/bin/sh -eu
# Ensure git worktree readiness and create an isolated worktree.
# Usage: sh ensure-worktree.sh <branch-name>
# Output: JSON with worktree_path and branch

set -eu

branch_name="${1:-}"

if [ -z "$branch_name" ]; then
  echo '{"error": "branch name is required"}' >&2
  exit 1
fi

# Defend the script surface: even if the PreToolUse branch gate is bypassed, this
# script creates a branch (git worktree add -b) and so must itself reject any
# name that is not the canonical work-YYYYMMDD-HHMMSS (named only by create.sh).
case "$branch_name" in
  work-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) : ;;
  *)
    echo '{"error": "branch name must match work-YYYYMMDD-HHMMSS (use create.sh)", "branch": "'"${branch_name}"'"}' >&2
    exit 1
    ;;
esac

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
