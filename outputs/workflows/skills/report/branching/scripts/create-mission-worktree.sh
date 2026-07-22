#!/bin/sh -eu
# Create a mission-named, persistent worktree at .worktrees/<slug>/ on a fresh
# work-YYYYMMDD-HHMMSS branch cut from the base branch (default: main). The
# DIRECTORY is the descriptive mission slug; the BRANCH inside is an ordinary
# work-* branch (the branch-name invariant is preserved). Copies the root .env
# into the worktree (as ensure-worktree.sh does).
#
# When an origin remote is configured, origin/<base> is fetched first so the
# worktree starts from the merged tip, not a stale local ref (a configured but
# unreachable origin fails loudly rather than degrading to the local base). The
# base is then resolved to a concrete commit SHA (origin/<base>, else the local
# ref) before it reaches `git worktree add`, so git's remote-tracking DWIM can
# never discard the -b and land the worktree on the base branch itself; and the
# reported "branch" is read back from the worktree's real HEAD, so the output is
# an observation, not a restatement of intent. Fails loudly if the base resolves
# to no commit, or if the created worktree's HEAD ever disagrees with the branch.
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

# Start from the MERGED base, not a stale local ref. When an `origin` remote is
# configured, fetch it first so origin/<base> reflects the true merged tip: a
# desk whose local <base> trails origin would otherwise cut the worktree from a
# stale commit — blind to already-merged PRs and to the rulings recorded in
# origin's mission.md — producing duplicate work that later needs a unification
# merge. Fail loudly if a configured origin is unreachable; never silently fall
# back to a possibly-stale local ref (workaholic:operation — delivery from the
# merged base; workaholic:implementation — fail loud, don't degrade silently).
# A repo with no origin (a purely local project) keeps working from its local
# ref, surfaced. Runs BEFORE `git worktree add`, so a fetch failure creates no
# worktree.
if git config --get remote.origin.url >/dev/null 2>&1; then
  if git fetch origin "${base}" 1>&2; then
    :
  elif git ls-remote --exit-code origin >/dev/null 2>&1; then
    # origin is reachable but carries no <base> ref — a legitimately
    # local-only base branch. Fall back to the local ref, surfaced below.
    echo "note: origin has no '${base}' ref; resolving base from the local ref" >&2
  else
    echo '{"error": "origin unreachable — refusing to cut a mission worktree from a possibly-stale local base", "base": "'"${base}"'"}' >&2
    exit 1
  fi
fi

# Resolve the base to a concrete commit SHA that git cannot re-interpret. A bare
# NAME handed to `git worktree add` is resolved by git itself: with no local
# branch of that name but a matching remote-tracking ref, git's DWIM silently
# creates a local branch tracking the remote, DISCARDS the explicit -b, and
# checks THAT out — so a `main` base on a desk/fresh-clone with no local `main`
# lands the worktree on `main` while the JSON still claims the minted work-*
# branch (and manufactures a stray local `main`). Pin it to a SHA up front so -b
# always takes effect and no stray branch is created. Prefer origin/<base> — the
# merged source of truth, freshened by the fetch above — then the local ref
# (surfaced), and fail loudly, naming the base, when neither resolves. This
# ordering is the fix: preferring the local ref first is what cut worktrees from
# a stale base.
if base_sha="$(git rev-parse --verify --quiet "origin/${base}^{commit}")"; then
  :
elif base_sha="$(git rev-parse --verify --quiet "${base}^{commit}")"; then
  echo "note: no origin/${base}; resolving base from the local '${base}' ref" >&2
else
  echo '{"error": "base does not resolve to a commit (no local branch, no origin ref)", "base": "'"${base}"'"}' >&2
  exit 1
fi

# Branch from the resolved base so the worktree starts on a clean, merged base —
# uncommitted work in the main tree stays in the main tree. Send git's progress
# chatter ("Preparing worktree", "HEAD is now at ...") to stderr so stdout
# carries only the JSON result.
git worktree add -b "${branch}" "${worktree_path}" "${base_sha}" >&2

# Report an OBSERVATION, not the minted name. git said what it did on stderr,
# where the JSON-parsing caller never looks; read the worktree's real HEAD and
# reconcile it with the branch we asked for. A mission worktree that landed on
# the wrong branch is not a result to hand back with exit 0 — fail loudly,
# reporting both names.
actual_branch="$(git -C "${worktree_path}" rev-parse --abbrev-ref HEAD)"
if [ "${actual_branch}" != "${branch}" ]; then
  echo '{"error": "worktree HEAD disagrees with the minted branch", "expected": "'"${branch}"'", "actual": "'"${actual_branch}"'", "worktree_path": "'"${worktree_path}"'"}' >&2
  exit 1
fi

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

# Report the OBSERVED branch (verified above to equal the minted name), so the
# contract is an observation of the worktree's HEAD, not a restatement of intent.
echo '{"worktree_path": "'"${worktree_path}"'", "branch": "'"${actual_branch}"'", "slug": "'"${slug}"'", "port_base": '"${port_base}"', "dev_port": '"${dev_port}"', "docs_port": '"${docs_port}"'}'
