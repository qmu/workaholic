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

# Credentials protocol (2026-07-13, generalized 2026-07-26): development credentials live
# in git-ignored env file(s) the project reads, and worktree creation carries them into
# the new worktree — git worktree add alone never brings an ignored file along. Carry
# EVERY env file the project reads (not the root one by assumption) via the shared carrier
# — the same one create-mission-worktree.sh uses, so the two creators cannot drift — so a
# subdirectory-env project is genuinely provisioned rather than getting a credential-less
# worktree that fails silently. Copies, not symlinks, so worktrees diverge independently.
. "${SCRIPT_DIR}/lib/carry-worktree-env.sh"
carried="$(carry_worktree_env "$repo_root" "$worktree_path")"
env_json="$(carry_worktree_env_json "$carried")"

# Report what was carried (empty array = no project env file found, stated explicitly).
echo '{"worktree_path": "'"${worktree_path}"'", "branch": "'"${branch_name}"'", "env_files_carried": '"${env_json}"'}'
