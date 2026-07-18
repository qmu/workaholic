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

# Exclude .worktrees/ and .env via the shared .git/info/exclude BEFORE creating
# the worktree, so a stray `git add -A` in the main tree can never embed the
# linked worktree as a gitlink (see lib/ensure-git-excludes.sh — shared with
# create-mission-worktree.sh so the two creators cannot drift).
SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/ensure-git-excludes.sh"
ensure_git_excludes "$repo_root"

git worktree add -b "${branch_name}" "${worktree_path}" HEAD

# Credentials protocol (2026-07-13): development credentials live in ONE
# git-ignored .env at the repository root, and worktree creation carries it
# into the new worktree — git worktree add alone never brings an ignored
# file along. A COPY, not a symlink, so worktrees can diverge credentials
# independently; silently skipped when the root has no .env.
if [ -f "${repo_root}/.env" ]; then
  cp "${repo_root}/.env" "${worktree_path}/.env"
fi

echo '{"worktree_path": "'"${worktree_path}"'", "branch": "'"${branch_name}"'"}'
