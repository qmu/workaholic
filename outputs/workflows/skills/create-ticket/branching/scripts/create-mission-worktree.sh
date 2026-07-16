#!/bin/sh -eu
# Create a mission-named, persistent worktree at .worktrees/<slug>/ on a fresh
# work-YYYYMMDD-HHMMSS branch cut from the base branch (default: main). The
# DIRECTORY is the descriptive mission slug; the BRANCH inside is an ordinary
# work-* branch (the branch-name invariant is preserved). Copies the root .env
# into the worktree (as ensure-worktree.sh does).
#
# Usage: create-mission-worktree.sh <slug> [base-branch]
# Output: {"worktree_path": "...", "branch": "work-YYYYMMDD-HHMMSS", "slug": "..."}

set -eu

SCRIPT_DIR=$(dirname "$0")
slug="${1:-}"
base="${2:-main}"

if [ -z "$slug" ]; then
  echo '{"error": "slug is required"}' >&2
  exit 1
fi

# The mission slug names the worktree DIRECTORY; keep it filesystem-safe.
case "$slug" in
  [a-z0-9]*) : ;;
  *) echo '{"error": "slug must start with [a-z0-9]", "slug": "'"${slug}"'"}' >&2; exit 1 ;;
esac
case "$slug" in
  *[!a-z0-9-]*) echo '{"error": "slug must match ^[a-z0-9][a-z0-9-]*$", "slug": "'"${slug}"'"}' >&2; exit 1 ;;
esac

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
worktree_path="${repo_root}/.worktrees/${slug}"

if git worktree list --porcelain | grep -q "worktree ${worktree_path}$"; then
  echo '{"error": "worktree already exists", "worktree_path": "'"${worktree_path}"'"}' >&2
  exit 1
fi

# Mint a canonical work-YYYYMMDD-HHMMSS branch name (same format as create.sh);
# the worktree branch stays policy-conformant even though the dir is mission-named.
branch="work-$(date +%Y%m%d-%H%M%S)"
if git show-ref --verify --quiet "refs/heads/${branch}"; then
  echo '{"error": "branch already exists (retry in a moment)", "branch": "'"${branch}"'"}' >&2
  exit 1
fi

mkdir -p "${repo_root}/.worktrees"

# Exclude .worktrees/ and .env via the shared .git/info/exclude (see
# lib/ensure-git-excludes.sh — shared with ensure-worktree.sh so the two
# creators cannot drift).
. "${SCRIPT_DIR}/lib/ensure-git-excludes.sh"
ensure_git_excludes "$repo_root"

# Branch from the base (default main) so the worktree starts on a clean, merged
# base — uncommitted work in the main tree stays in the main tree. Send git's
# progress chatter ("Preparing worktree", "HEAD is now at ...") to stderr so
# stdout carries only the JSON result.
git worktree add -b "${branch}" "${worktree_path}" "${base}" >&2

# Carry the single-source root .env into the worktree (a copy, skipped when absent).
if [ -f "${repo_root}/.env" ]; then
  cp "${repo_root}/.env" "${worktree_path}/.env"
fi

# Assign a unique local port base so concurrent worktrees' dev/docs servers do not
# collide on localhost, and record it in the worktree's .env for the project's
# serve scripts to read (with the project's own env precedence).
ports="$(sh "${SCRIPT_DIR}/allocate-worktree-port.sh")"
port_base="$(printf '%s' "$ports" | sed -n 's/.*"port_base":[ ]*\([0-9][0-9]*\).*/\1/p')"
dev_port="$(printf '%s' "$ports" | sed -n 's/.*"dev_port":[ ]*\([0-9][0-9]*\).*/\1/p')"
docs_port="$(printf '%s' "$ports" | sed -n 's/.*"docs_port":[ ]*\([0-9][0-9]*\).*/\1/p')"
{
  printf 'WORKAHOLIC_PORT_BASE=%s\n' "$port_base"
  printf 'WORKAHOLIC_DEV_PORT=%s\n' "$dev_port"
  printf 'WORKAHOLIC_DOCS_PORT=%s\n' "$docs_port"
} >> "${worktree_path}/.env"

echo '{"worktree_path": "'"${worktree_path}"'", "branch": "'"${branch}"'", "slug": "'"${slug}"'", "port_base": '"${port_base}"', "dev_port": '"${dev_port}"', "docs_port": '"${docs_port}"'}'
