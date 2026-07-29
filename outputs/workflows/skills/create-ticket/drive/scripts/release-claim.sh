#!/bin/sh -eu
# Release a PR-unit that will NOT be finished: delete its claim branch and tear its
# worktree down, so the unit returns to the pickable pool.
#
# There are exactly two ways a claim is released, and this script is only the second:
#   * MERGE -- the normal path. A merged branch's commits are on the base, so its
#     claim leaves the unmerged set by definition. No script, no bookkeeping.
#   * DISCARD -- this script. A deliberate abandonment of unfinished work.
#
# Usage: release-claim.sh <unit-id>
# Output: {"released": true, "unit": "...", "branch": "...", "worktree_removed": bool,
#          "remote_branch_deleted": bool, "local_branch_deleted": bool}
#
# ORDER IS THE DESIGN. Origin is checked first, then the worktree is torn down, then
# the remote branch is deleted. Deleting the remote first would publish "this unit is
# free" while the worktree still holds unpushed work -- and the teardown REFUSES a
# dirty worktree (cleanup-mission-worktree.sh never discards uncommitted changes), so
# a release that hits that refusal must not have already dropped the claim.
#
# Run it from the MAIN checkout: git cannot remove the worktree you are standing in.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/claims.sh"

unit="${1:-}"
if [ -z "$unit" ]; then
    echo 'Usage: release-claim.sh <unit-id>' >&2
    exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo '{"released": false, "reason": "not inside a git repository"}' >&2
    exit 1
fi
repo_root="$(git rev-parse --show-toplevel)"

has_origin=false
if git config --get remote.origin.url >/dev/null 2>&1; then
    has_origin=true
    if [ "$(claims_fetch)" != "true" ]; then
        echo '{"released": false, "reason": "origin_unreachable", "detail": "the remote claim branch could not be deleted; nothing was torn down"}' >&2
        exit 1
    fi
fi

# Resolve the claim branch: the reader is the authority (it is what every other
# runner sees), with the local worktree's HEAD as the fallback for a claim whose
# remote branch is already gone -- releasing that is still a legitimate cleanup.
branch=""
rows=$(claims_scan "$(claims_base)")
if [ -n "$rows" ]; then
    while IFS='	' read -r held_unit held_branch _at _stale _arts; do
        if [ "$held_unit" = "$unit" ]; then
            branch="$held_branch"
            break
        fi
    done <<EOF
$rows
EOF
fi
worktree_path="${repo_root}/.worktrees/${unit}"
if [ -z "$branch" ] && [ -d "$worktree_path" ]; then
    branch="$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
fi

# Tear the worktree down through the sanctioned cleaner -- it refuses a dirty
# worktree and only deletes a branch matching the ephemeral work-* pattern.
worktree_removed=false
if [ -d "$worktree_path" ]; then
    cleanup_out=$( ( cd "$repo_root" && sh "${SCRIPT_DIR}/../../branching/scripts//cleanup-mission-worktree.sh" "$unit" ) ) || {
        echo '{"released": false, "reason": "worktree_teardown_refused", "unit": "'"${unit}"'", "detail": "uncommitted work in the claim worktree; the claim was NOT released"}' >&2
        exit 1
    }
    case "$cleanup_out" in
        *'"worktree_removed": true'*) worktree_removed=true ;;
    esac
fi

remote_deleted=false
if [ "$has_origin" = true ] && [ -n "$branch" ]; then
    if git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1; then
        git push --quiet origin --delete "$branch" >&2 || {
            echo '{"released": false, "reason": "remote_delete_failed", "unit": "'"${unit}"'", "branch": "'"${branch}"'"}' >&2
            exit 1
        }
        remote_deleted=true
    fi
fi

# The cleaner already dropped the local branch when it removed the worktree; this
# covers the worktree-already-gone case. Guarded by the same ephemeral pattern, so a
# release can never delete main or a hand-made branch.
local_deleted=false
if [ -n "$branch" ] && git show-ref --verify --quiet "refs/heads/${branch}"; then
    case "$branch" in
        work-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9])
            git branch -D "$branch" >/dev/null 2>&1 && local_deleted=true || true
            ;;
    esac
fi

printf '{"released": true, "unit": "%s", "branch": "%s", "worktree_removed": %s, "remote_branch_deleted": %s, "local_branch_deleted": %s}\n' \
    "$unit" "$branch" "$worktree_removed" "$remote_deleted" "$local_deleted"
