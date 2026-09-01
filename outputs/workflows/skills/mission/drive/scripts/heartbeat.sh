#!/bin/sh -eu
# Refresh a claim's LIVENESS SIGNAL, so a run that is still working is never mistaken
# for one that died and had its unit taken over.
#
# Usage: heartbeat.sh <unit-id>
# Output: {"beat": bool, "unit": "...", "branch": "...", "reason": "..."}
#
# THE BRANCH TIP *IS* THE HEARTBEAT (see lib/claims.sh). There is no lock file, no
# heartbeat file, and no server -- the protocol forbids all three, and each of them
# leaks when a runner dies, which is the exact failure the claim protocol was built to
# avoid. Instead this pushes an EMPTY commit onto the unit's own claim branch: it
# changes no file, so it never appears in the PR diff, and it is cleaned up by the very
# merge or release that already cleans up the claim. Any ordinary work commit refreshes
# the same signal, which is correct -- a run that is committing is a run that is alive
# -- so this script is only needed during a long stretch with nothing to commit.
#
# CALL IT AT A BOUNDED INTERVAL, comfortably inside
# WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES (default 30): a unit driven for an hour with
# no commit and no beat becomes resumable while its run is still working, and two
# runners on one worktree is worse than a stalled unit. Roughly every ten minutes, or
# once per ticket, is the shape /drive uses.
#
# NEVER LOAD-BEARING, and deliberately so: a failed beat is reported (`beat: false`
# with a reason) and exits 0. A transient push failure must not kill a run that is
# otherwise doing fine -- the cost of a missed beat is bounded (the unit looks
# resumable sooner than it should, and the takeover race then resolves in git), while
# the cost of aborting a working run is the whole run.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

unit="${1:-}"
if [ -z "$unit" ]; then
    echo 'Usage: heartbeat.sh <unit-id>' >&2
    exit 1
fi

report() {
    printf '{"beat": %s, "unit": "%s", "branch": "%s", "reason": "%s"}\n' "$1" "$unit" "${2:-}" "${3:-}"
    exit 0
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    report false "" not_a_repository
fi
# RESOLVE THE MAIN CHECKOUT'S ROOT, not the current tree's. `drive/SKILL.md` §4 tells a run
# to stand INSIDE the unit's worktree and to beat as step 0 of every ticket, and there
# `--show-toplevel` answers the worktree's own root -- composing
# `.worktrees/<unit>/.worktrees/<unit>`, which never exists, so the beat silently did
# nothing in exactly the directory the workflow names. `--git-common-dir` names the shared
# git directory from either tree (relative from the main checkout, absolute from a
# worktree), so cd into it and take its parent rather than parsing the string.
repo_root=""
git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null || true)"
if [ -n "$git_common_dir" ]; then
    repo_root="$(cd -- "$git_common_dir" 2>/dev/null && cd .. && pwd)" || repo_root=""
fi
if [ -z "$repo_root" ]; then
    repo_root="$(git rev-parse --show-toplevel)"
fi
worktree_path="${repo_root}/.worktrees/${unit}"

# The beat is pushed FROM THE UNIT'S OWN WORKTREE. Beating from anywhere else would
# mean guessing which branch the unit is on, and a heartbeat written onto the wrong
# branch is worse than none: it would keep an idle claim looking alive forever.
if [ ! -d "$worktree_path" ]; then
    report false "" no_worktree
fi

branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [ -z "$branch" ] || [ "$branch" = "HEAD" ]; then
    report false "" no_branch
fi

# A DIRTY WORKTREE STILL BEATS. The run is plainly alive -- that is what dirty means --
# and the empty commit records nothing from the working tree, so uncommitted work is
# neither staged, committed, nor disturbed.
( cd "$worktree_path" && sh "${SCRIPT_DIR}/../../commit/scripts//commit.sh" --allow-empty \
    "Refresh heartbeat" \
    "" \
    "None -- coordination only; the beat changes no file and never reaches the PR diff" \
    "None" "None" \
    "The claim branch tip advances, so the shared claim scan keeps reporting this unit active rather than resumable" ) >/dev/null 2>&1 \
    || report false "$branch" commit_failed

git -C "$worktree_path" push --quiet origin "$branch" >/dev/null 2>&1 \
    || report false "$branch" push_failed

report true "$branch" ""
