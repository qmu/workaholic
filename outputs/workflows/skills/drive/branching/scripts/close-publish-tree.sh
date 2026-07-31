#!/bin/sh -eu
# Close the publish tree: remove the .publish/ worktree and delete the local
# publish-main branch.
#
#   close-publish-tree.sh [base-branch]     # base defaults to main
#
# Output (stdout, exit 0 for a reported outcome):
#   {"ok": true,  "removed": true|false, "branch_deleted": true|false, "path": "<abs>"}
#   {"ok": false, "reason": "dirty_publish_tree"|"unpublished_commits", ...}
#
# Idempotent when the publish tree is already gone (`removed: false`).
#
# IT REFUSES TO DESTROY RECOVERABLE STATE, in the two shapes that state takes —
# the same stance cleanup-mission-worktree.sh holds:
#
#   - `dirty_publish_tree`: uncommitted work in the tree. An interrupted run's
#     half-written artifact is never discarded by a bookkeeping call.
#   - `unpublished_commits`: a CLEAN tree whose publish-main tip is reachable from
#     NO remote-tracking ref of origin. This is exactly what a `diverged` publish
#     leaves behind, and it is the more dangerous case precisely because the tree
#     looks tidy: deleting the branch there would destroy the one copy of the
#     artifact. Publish it or discard it deliberately; close will not decide.
#
# THE QUESTION IS "IS THIS PUSHED ANYWHERE?", NOT "DID THIS REACH THE BASE?".
# The test used to be ancestry against origin/<base> alone, which silently assumed
# every publish lands on the base. That stopped being true at decision J4, which
# made `publish-tree-pr.sh` — pushing publish-main to a remote `work-*` branch
# behind a pull request — the DEFAULT path: the commit is safely on origin, and by
# construction not on origin/<base> until a human merges the PR, which J4 says has
# no deadline. So the documented two-line sequence (publish, then close) always
# ended in a refusal, and every /ticket, /mission and /fb run left `.publish/` and
# a `publish-main` branch behind. That is worse than untidy: a refusal that fires
# on the happy path trains its callers to ignore it, and the one refusal that
# matters gets ignored with it.
#
# Reachability from any `origin/*` ref answers the real question and needs nothing
# threaded in from the publishing script, so the two stay independently callable
# and a tree published in one session still closes correctly in a later one. The
# widening is bounded: a stale remote-tracking ref could in principle make an
# unpublished tip look published, but `publish-tree-pr.sh` pushes immediately
# before the close, so the ref it relies on is the one it just wrote.

set -eu

base="${1:-main}"
PUBLISH_BRANCH="publish-main"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
publish_path="${repo_root}/.publish"

removed=false
branch_deleted=false

is_registered=false
if git worktree list --porcelain | grep -q "^worktree ${publish_path}$"; then
  is_registered=true
fi

# --- Both refusals are decided BEFORE anything is removed --------------------
# Removing the worktree and then refusing the branch would leave the caller half
# closed, with the artifact reachable only from a ref they were not told about.
if [ "$is_registered" = "true" ] \
  && [ -n "$(git -C "$publish_path" status --porcelain 2>/dev/null)" ]; then
  printf '{"ok": false, "reason": "dirty_publish_tree", "path": "%s", "detail": "uncommitted changes; nothing was removed"}\n' "$publish_path"
  exit 0
fi

if git show-ref --verify --quiet "refs/heads/${PUBLISH_BRANCH}"; then
  # Reachable from ANY remote-tracking ref of origin — the base for a direct
  # publish, the pushed `work-*` branch for the default PR publish. `--contains`
  # asks exactly this and is indifferent to which path put it there.
  publish_sha=$(git rev-parse --verify --quiet "refs/heads/${PUBLISH_BRANCH}" || printf '')
  containing=""
  if [ -n "$publish_sha" ]; then
    containing=$(git branch --remotes --contains "$publish_sha" --format='%(refname:short)' 2>/dev/null | grep '^origin/' || true)
  fi
  if [ -z "$containing" ]; then
    printf '{"ok": false, "reason": "unpublished_commits", "branch": "%s", "path": "%s", "detail": "no remote-tracking ref of origin contains publish-main tip %s (checked the base origin/%s and every pushed branch); nothing was removed — publish or discard them deliberately"}\n' \
      "$PUBLISH_BRANCH" "$publish_path" "$(printf '%.8s' "$publish_sha")" "$base"
    exit 0
  fi
  branch_pending=true
else
  branch_pending=false
fi

if [ "$is_registered" = "true" ]; then
  git worktree remove "$publish_path" >&2
  removed=true
fi

git worktree prune >&2

if [ "$branch_pending" = "true" ]; then
  # -D, not -d, and deliberately: `-d` asks "is this merged into HEAD or its
  # upstream", which is the wrong question — the caller's HEAD is whatever branch
  # they happen to be on, so a published commit would still be refused there.
  # The right question was already answered above, and more precisely: the
  # publish-main tip is reachable from some pushed ref of origin. Deleting the
  # local ref then discards nothing.
  git branch -D "$PUBLISH_BRANCH" >&2
  branch_deleted=true
fi

printf '{"ok": true, "removed": %s, "branch_deleted": %s, "path": "%s"}\n' "$removed" "$branch_deleted" "$publish_path"
