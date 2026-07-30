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
#   - `unpublished_commits`: a CLEAN tree whose publish-main carries commits not
#     reachable from origin/<base>. This is exactly what a `diverged` publish
#     leaves behind, and it is the more dangerous case precisely because the tree
#     looks tidy: deleting the branch there would destroy the one copy of the
#     artifact. Publish it or discard it deliberately; close will not decide.

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
  remote_ref="refs/remotes/origin/${base}"
  if git rev-parse --verify --quiet "$remote_ref" >/dev/null 2>&1 \
    && git merge-base --is-ancestor "$PUBLISH_BRANCH" "$remote_ref"; then
    :
  else
    printf '{"ok": false, "reason": "unpublished_commits", "branch": "%s", "path": "%s", "detail": "publish-main carries commits not on origin/%s; nothing was removed — publish or discard them deliberately"}\n' \
      "$PUBLISH_BRANCH" "$publish_path" "$base"
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
  # The right question was already answered above, and more precisely: every
  # commit on publish-main is reachable from origin/<base>. Deleting the local
  # ref then discards nothing.
  git branch -D "$PUBLISH_BRANCH" >&2
  branch_deleted=true
fi

printf '{"ok": true, "removed": %s, "branch_deleted": %s, "path": "%s"}\n' "$removed" "$branch_deleted" "$publish_path"
