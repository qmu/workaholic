#!/bin/sh -eu
# Create a mission-named, persistent worktree at .worktrees/<slug>/ on a fresh
# work-YYYYMMDD-HHMMSS branch cut from the base branch (default: main). The
# DIRECTORY is the descriptive mission slug; the BRANCH inside is an ordinary
# work-* branch (the branch-name invariant is preserved). Carries every env file
# the project actually reads into the worktree via the shared carrier
# (lib/carry-worktree-env.sh, also used by ensure-worktree.sh so they cannot drift)
# and reports what was carried; the WORKAHOLIC_* port vars go into the carried root
# .env when present, else a separate .env.worktree (never a fake root .env).
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
# RESUME MODE (--branch <existing-work-branch>) attaches the worktree to a branch that
# ALREADY EXISTS on origin instead of minting one from the base. It exists for
# claim.sh's takeover path: a unit whose runner died is continued from the work that
# SURVIVES -- the pushed branch tip -- and cutting a fresh worktree from origin/main
# would silently restart it, re-driving tickets that branch already archived. The two
# modes share everything below the checkout (env carry, port allocation, HEAD
# reconciliation, size reporting), which is why this is a mode here rather than a
# second creator free to drift from this one.
#
# Usage: create-mission-worktree.sh <slug> [base-branch]
#        create-mission-worktree.sh --branch <existing-branch> <slug>
# Output: {"worktree_path": "...", "branch": "work-YYYYMMDD-HHMMSS", "slug": "..."}

set -eu

SCRIPT_DIR=$(dirname "$0")

existing_branch=""
if [ "${1:-}" = "--branch" ]; then
  existing_branch="${2:-}"
  if [ -z "$existing_branch" ]; then
    echo '{"error": "--branch requires a branch name"}' >&2
    exit 1
  fi
  shift 2
fi

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
# In resume mode the branch is GIVEN, not minted -- it is the claim's published branch,
# and re-minting one would be the restart this mode exists to prevent.
if [ -n "$existing_branch" ]; then
  branch="$existing_branch"
else
  branch="work-$(date +%Y%m%d-%H%M%S)"
  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    echo '{"error": "branch already exists (retry in a moment)", "branch": "'"${branch}"'"}' >&2
    exit 1
  fi
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
#
# Resume mode fetches the CLAIM branch instead: its tip is the surviving work, and the
# base is irrelevant to where this worktree starts.
if [ -n "$existing_branch" ]; then
  git config --get remote.origin.url >/dev/null 2>&1 \
    || { echo '{"error": "resuming a claim needs an origin remote — the branch tip is the surviving work", "branch": "'"${branch}"'"}' >&2; exit 1; }
  git fetch origin "${branch}" 1>&2 \
    || { echo '{"error": "could not fetch the claim branch from origin", "branch": "'"${branch}"'"}' >&2; exit 1; }
elif git config --get remote.origin.url >/dev/null 2>&1; then
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
if [ -n "$existing_branch" ]; then
  base_sha="$(git rev-parse --verify --quiet "origin/${branch}^{commit}")" || {
    echo '{"error": "no origin ref for the claim branch — nothing to resume", "branch": "'"${branch}"'"}' >&2
    exit 1
  }
elif base_sha="$(git rev-parse --verify --quiet "origin/${base}^{commit}")"; then
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
#
# Resume mode instead ATTACHES to the existing branch at origin's tip. `-B` resets a
# stale local copy of that branch onto origin, which is the right reading (a published
# claim's truth is origin) — but only after checking the local ref is not AHEAD.
# Discarding unpushed local commits is exactly the destructive git the drive contract
# forbids, so an ahead local branch is refused, not reset: a human decides what happens
# to work that was never published.
if [ -n "$existing_branch" ]; then
  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    ahead="$(git rev-list --count "origin/${branch}..${branch}" 2>/dev/null || echo 0)"
    if [ "${ahead}" -gt 0 ]; then
      echo '{"error": "local branch is ahead of origin — refusing to reset it onto the published tip", "branch": "'"${branch}"'", "ahead": '"${ahead}"'}' >&2
      exit 1
    fi
  fi
  git worktree add -B "${branch}" "${worktree_path}" "${base_sha}" >&2
else
  git worktree add -b "${branch}" "${worktree_path}" "${base_sha}" >&2
fi

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

# Carry EVERY env file the project reads into the worktree (not the root one by
# assumption) via the shared carrier, so a subdirectory-env project is actually
# provisioned instead of getting a credential-less worktree that only looks provisioned.
# `carried` is a newline list of the repo-relative env files copied ("" when none).
. "${SCRIPT_DIR}/lib/carry-worktree-env.sh"
carried="$(carry_worktree_env "$repo_root" "$worktree_path")"

# Assign a unique local port base so concurrent worktrees' dev/docs servers do not
# collide on localhost. Where the WORKAHOLIC_* port vars go is decided by whether a root
# .env was actually carried: append them to that .env only if the project reads it.
# Otherwise write them to a clearly-separate .env.worktree -- NEVER fabricate a bare root
# .env whose only content is port vars, which is exactly the artifact that made the
# provisioning gap look like success and disguised itself as a "no credentials" finding.
ports="$(sh "${SCRIPT_DIR}/allocate-worktree-port.sh")"
port_base="$(printf '%s' "$ports" | sed -n 's/.*"port_base":[ ]*\([0-9][0-9]*\).*/\1/p')"
dev_port="$(printf '%s' "$ports" | sed -n 's/.*"dev_port":[ ]*\([0-9][0-9]*\).*/\1/p')"
docs_port="$(printf '%s' "$ports" | sed -n 's/.*"docs_port":[ ]*\([0-9][0-9]*\).*/\1/p')"
if printf '%s\n' "$carried" | grep -Fxq ".env"; then
  port_env_file=".env"
else
  port_env_file=".env.worktree"
fi
{
  printf 'WORKAHOLIC_PORT_BASE=%s\n' "$port_base"
  printf 'WORKAHOLIC_DEV_PORT=%s\n' "$dev_port"
  printf 'WORKAHOLIC_DOCS_PORT=%s\n' "$docs_port"
} >> "${worktree_path}/${port_env_file}"

# Report what was carried, plainly, so the provisioning gap is visible at CREATION time --
# an empty env_files_carried says "no project env file was found" explicitly (not by
# omission), and port_env_file names where the port vars landed.
env_json="$(carry_worktree_env_json "$carried")"

# REPORT THE COST AT CREATION. A worktree used to be created silently and its several
# hundred megabytes never appeared in any output, so growth stayed invisible until a disk
# filled -- 53 GB across four repositories, discovered by a container build failing on
# "no space left on device". `workaholic:implementation` / objective-documentation: the
# cost is an observable fact, and the moment it is allocated is the moment to state it.
# This is the checkout only; a dependency install (250-620 MB observed) lands later, which
# is why `survey-worktrees.sh` re-measures rather than trusting this number afterwards.
size_kb=$(du -sk "$worktree_path" 2>/dev/null | awk '{print $1}')
[ -n "$size_kb" ] || size_kb=0
size_bytes=$((size_kb * 1024))

# Report the OBSERVED branch (verified above to equal the minted name), so the
# contract is an observation of the worktree's HEAD, not a restatement of intent.
echo '{"worktree_path": "'"${worktree_path}"'", "branch": "'"${actual_branch}"'", "slug": "'"${slug}"'", "port_base": '"${port_base}"', "dev_port": '"${dev_port}"', "docs_port": '"${docs_port}"', "env_files_carried": '"${env_json}"', "port_env_file": "'"${port_env_file}"'", "size_bytes": '"${size_bytes}"'}'
