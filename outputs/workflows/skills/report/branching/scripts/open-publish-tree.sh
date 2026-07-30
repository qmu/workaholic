#!/bin/sh -eu
# Open the PUBLISH TREE: a checkout of origin/<base> that is independent of the
# caller's working tree, so an artifact can be written and pushed to the base
# branch without depending on — or disturbing — whatever the developer is doing.
#
#   open-publish-tree.sh [base-branch]     # base defaults to main
#
# Output (stdout, exit 0 for a reported outcome):
#   {"ok": true,  "path": "<abs>", "branch": "publish-main", "base": "origin/<base>", "sha": "<sha>"}
#   {"ok": false, "reason": "no_origin"|"origin_unreachable"|"base_unresolved"
#                          |"dirty_publish_tree", ...}
#
# A PUBLISH TREE IS NOT A CLAIM WORKTREE. It holds no unit, is never pushed as a
# branch, and is disposable at any moment. `.worktrees/<unit-id>/` is claim-born
# and ship-torn and belongs to exactly one PR-unit; `.publish/` belongs to
# nobody and is reset on every open.
#
# THE BRANCH IS NAMED, AND THAT IS LOAD-BEARING. commit.sh refuses a detached
# HEAD, and the publish commit must go through commit.sh so it inherits the
# subject gate and the trailers. The name is deliberately NOT work-*: work-* is
# the claim vocabulary that the claim scan keys on, and an ambiguous name here
# would let a publish tree be misread as an in-flight claim.
#
# NO ORIGIN FAILS LOUDLY. A publication nobody else can see is not a
# publication — the same writer stance claim.sh takes.
#
# IT REFUSES A DIRTY PUBLISH TREE rather than resetting over it. A reset that
# silently discarded a half-written artifact from an interrupted run is the
# failure this refusal exists to prevent; the leftover tree is recoverable
# state, not garbage.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
base="${1:-main}"
PUBLISH_BRANCH="publish-main"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
publish_path="${repo_root}/.publish"

# --- 1. Origin is mandatory --------------------------------------------------
if ! git config --get remote.origin.url >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "no_origin", "detail": "a publication is a push to %s; this repository has no origin remote"}\n' "$base"
  exit 0
fi

if ! git fetch --quiet origin "$base" >&2; then
  printf '{"ok": false, "reason": "origin_unreachable", "base": "%s"}\n' "$base"
  exit 0
fi

sha=$(git rev-parse --verify --quiet "refs/remotes/origin/${base}^{commit}" || true)
if [ -z "$sha" ]; then
  printf '{"ok": false, "reason": "base_unresolved", "base": "%s", "detail": "origin has no %s ref"}\n' "$base" "$base"
  exit 0
fi

# --- 2. Exclude the publish tree BEFORE it exists ----------------------------
# Same seam and same reason as .worktrees/: git does not auto-ignore a linked
# worktree directory, so a stray `git add -A` in the main tree would embed it as
# a gitlink.
. "${SCRIPT_DIR}/lib/ensure-git-excludes.sh"
ensure_git_excludes "$repo_root"

# Drop registrations for worktrees whose directories are gone, so a crashed run
# cannot make the path permanently unusable.
git worktree prune >&2

registered=false
if git worktree list --porcelain | grep -q "^worktree ${publish_path}$"; then
  registered=true
fi

# --- 3. Reuse (reset) or create ----------------------------------------------
if [ "$registered" = "true" ]; then
  # Uncommitted changes: refuse. Untracked files count — `??` rows are exactly
  # the half-written artifact this refusal protects.
  if [ -n "$(git -C "$publish_path" status --porcelain 2>/dev/null)" ]; then
    printf '{"ok": false, "reason": "dirty_publish_tree", "path": "%s", "detail": "the publish tree holds uncommitted changes; nothing was discarded"}\n' "$publish_path"
    exit 0
  fi
  # Idempotent open: one worktree, re-pointed at the base just fetched. `-B`
  # both moves the branch and syncs the working tree, so no second reset is
  # needed — and it is safe here only because the dirty check above already
  # refused everything uncommitted, tracked or not.
  git -C "$publish_path" checkout --quiet -B "$PUBLISH_BRANCH" "$sha" >&2
elif [ -e "$publish_path" ]; then
  # A directory at the path that git does not know about. Its contents are
  # unknown, so it is refused, never removed.
  printf '{"ok": false, "reason": "dirty_publish_tree", "path": "%s", "detail": "path exists but is not a registered worktree; remove it by hand once you have checked its contents"}\n' "$publish_path"
  exit 0
else
  # -B creates the publish branch or moves it to the resolved SHA, so a branch
  # left behind by a previous run is reused rather than colliding. It fails
  # loudly (as it should) if publish-main is checked out in another worktree.
  git worktree add -B "$PUBLISH_BRANCH" "$publish_path" "$sha" >&2
fi

# --- 4. Report an observation, not the intent --------------------------------
actual_branch="$(git -C "$publish_path" rev-parse --abbrev-ref HEAD)"
actual_sha="$(git -C "$publish_path" rev-parse HEAD)"
if [ "$actual_branch" != "$PUBLISH_BRANCH" ]; then
  printf '{"error": "publish tree HEAD disagrees with the publish branch", "expected": "%s", "actual": "%s", "path": "%s"}\n' \
    "$PUBLISH_BRANCH" "$actual_branch" "$publish_path" >&2
  exit 1
fi

printf '{"ok": true, "path": "%s", "branch": "%s", "base": "origin/%s", "sha": "%s"}\n' \
  "$publish_path" "$actual_branch" "$base" "$actual_sha"
