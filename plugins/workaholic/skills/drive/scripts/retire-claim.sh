#!/bin/sh -eu
# Retire a claim the oracle PROVED holds nothing: close its pull request, delete its remote
# branch, reap its worktree.
#
# Usage: retire-claim.sh <unit-id>
# Output: {"retired": bool, "unit": "...", "branch": "...", "pull_request": "...",
#          "pull_request_closed": "closed"|"already_closed"|"none"|"failed"|"not_attempted",
#          "remote_branch_deleted": "deleted"|"already_gone"|"failed"|"not_attempted",
#          "worktree_reaped": "reaped"|"absent"|"refused"|"not_attempted",
#          "reason": ""}
#         Always exit 0 — a refusal is an answer, and the caller (`/moderate`'s step) reports
#         it rather than dying on it.
#
# WHY IT EXISTS (2026-08-27, mission `deliver-and-retire-what-the-loop-already-proved-finished`).
# `superseded` (2026-08-26) means the claim's content already reached the base — a PROOF, not a
# suspicion. It is "reported, never acted on": `stalled-units` stops asking about it and
# `plan-units.sh` resurveys the work behind it. What nothing did was retire the CLAIM itself, so
# its branch, its worktree and its open pull request stayed forever and the claim table only ever
# grew. Measured on this repository on 2026-08-27: 7 claims, 4 of them `superseded`, two of those
# naming missions archived days ago, the oldest branch last touched 2026-08-21.
#
# WHAT MAKES A DESTRUCTIVE ACT SAFE HERE IS THE PROOF, AND NOTHING ELSE. `superseded` is one of
# exactly two verdicts the claim protocol classifies as a proof (`../reference/claims.md`,
# *Proofs and judgements*): the unit's tickets are archived on the base, or a merged pull request
# has this branch as its head. The branch can never land and holds no work. Every other verdict
# is a JUDGEMENT and is refused below BY ITS OWN NAME — `stale` says *look at this*,
# `queue_drained` says *a person is merging it*, `claim_active` says *a run is on it right now*,
# and acting on any of them is how a runner discards work somebody is still driving.
#
# THE ABSENCE OF A READING IS REFUSED BY ITS OWN NAME TOO. A branch whose merged-pull-request
# lookup came back `unanswerable` kept precisely the verdict it would have had without the
# lookup, which for a mission-grain claim is a NON-proof — so it is refused here anyway, and
# refused as `unanswerable` rather than under the local verdict word, because the reader must be
# sent to the lookup that failed rather than to a claim that looks live. `ambiguous_claim` is its
# own refusal for the same reason `release-claim.sh` gives it one: two live claims cannot arise
# from the sanctioned path, and picking one silently is how a runner tears down work another run
# is driving.
#
# IT RESOLVES THE UNIT THROUGH THE LIVE-ROW RULE, NEVER FIRST-MATCH (2026-08-27). A unit can be
# held by a `superseded` branch AND a live one — that is exactly the shape a fresh claim over a
# superseded one creates — and `claims_scan` walks refs in name order, so first-match is the
# OLDEST. Here that error is the dangerous direction of the two: it would retire whichever branch
# sorted first regardless of which one is alive. `claims_unit_resolution` / `claims_unit_row` are
# the one shared derivation, so the survey's offer, `claim.sh`'s refusal and this retirement
# cannot disagree about which branch a unit is.
#
# HOW REVERSIBLE EACH ACT IS, stated rather than assumed: a pull request closed in error is
# REOPENABLE on GitHub with its review history intact; a deleted remote branch is recoverable
# from the base's own history (its content is on the base — that is what `superseded` means) and
# from any local clone's reflog; the worktree is local and `claim.sh resume` rebuilds one at a
# branch tip. None of the three destroys work. That is a property of acting only on the proof,
# not a licence to widen the verdict set.
#
# THE ORDER IS CLOSE, DELETE, REAP, and it is the reverse of `release-claim.sh`'s on purpose.
# That script tears the worktree down FIRST because it discards UNFINISHED work and must not
# publish "this unit is free" over a worktree holding unpushed commits. Here there is no such
# work by construction, and the local worktree is the only step that can be refused for a reason
# outside this runner's control (`cleanup-mission-worktree.sh` refuses a dirty tree, which it
# must). Putting it last means a refusal there leaves the two REMOTE facts already correct, and a
# re-run finishes the job.
#
# EVERY STEP IS IDEMPOTENT AND EACH REPORTS ITS OWN WORD. An already-closed pull request, an
# already-deleted branch and an absent worktree are each a real SUCCESS, not a degradation:
# re-running retires nothing twice and reports the same shape. A step that fails is named and the
# remaining steps are attempted on their own merits rather than guessed at — the three acts are
# independent, so one failure is not evidence about the others.
#
# IT MERGES NOTHING, PUSHES INTO NO BRANCH, AND TOUCHES NO `.workaholic/` ARTIFACT. Its only
# writes are one REST `PATCH` closing a pull request and one branch delete; no commit is made
# anywhere, no mission is closed, no ticket is moved, and no story is edited.
#
# Run it from the MAIN checkout: git cannot remove the worktree you are standing in.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"
CLEANUP="${SCRIPT_DIR}/../../branching/scripts/cleanup-mission-worktree.sh"

unit="${1:-}"
if [ -z "$unit" ]; then
    echo 'Usage: retire-claim.sh <unit-id>' >&2
    exit 1
fi

BRANCH=""
PR=""
PR_STATE="unknown"
REMOTE_STATE="failed"
WORKTREE_STATE="absent"

json_str() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[[:cntrl:]]/ /g'
}

report() {
    printf '{"retired": %s, "unit": "%s", "branch": "%s", "pull_request": "%s", "pull_request_closed": "%s", "remote_branch_deleted": "%s", "worktree_reaped": "%s", "reason": "%s"}\n' \
        "$1" "$(json_str "$unit")" "$(json_str "$BRANCH")" "$(json_str "$PR")" \
        "$PR_STATE" "$REMOTE_STATE" "$WORKTREE_STATE" "$(json_str "${2:-}")"
    exit 0
}

# A REFUSAL REPORTS `not_attempted`, NEVER `failed` OR `absent`. Those are findings about the
# world — "there is no pull request", "the delete was rejected" — and a gate that never ran made
# no such finding. Reporting one would have the caller state as fact something this script never
# looked at.
refuse() {
    PR_STATE="not_attempted"
    REMOTE_STATE="not_attempted"
    WORKTREE_STATE="not_attempted"
    report false "$1"
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || refuse not_a_repository
repo_root="$(git rev-parse --show-toplevel)"

git config --get remote.origin.url >/dev/null 2>&1 || refuse no_origin
[ "$(claims_fetch)" = "true" ] || refuse origin_unreachable
# `claims_fetch` above ran in a command substitution, so the flag it set died with that
# subshell. Without it the merged-pull-request lookup is skipped `offline`, and a MISSION-grain
# claim whose pull request merged would never read `superseded` here at all — the very verdict
# this script exists to act on. `claim.sh` and `release-claim.sh` set it for the same reason.
CLAIMS_FETCH_OK=true
export CLAIMS_FETCH_OK

# Collect the lookup's unanswered set so an absent reading is refused as `unanswerable` rather
# than under whatever local verdict the row fell back to.
UNANSWERED_FILE=$(mktemp 2>/dev/null || printf '')
if [ -n "$UNANSWERED_FILE" ]; then
    CLAIMS_UNANSWERED_FILE="$UNANSWERED_FILE"
    export CLAIMS_UNANSWERED_FILE
    trap 'rm -f "$UNANSWERED_FILE"' EXIT INT TERM
fi

ROWS=$(claims_scan "$(claims_base)" 2>/dev/null || true)
[ -n "$ROWS" ] || refuse no_claims

case "$(claims_unit_resolution "$ROWS" "$unit")" in
    none)      refuse no_such_claim ;;
    ambiguous) BRANCH=$(claims_unit_live_branches "$ROWS" "$unit"); refuse ambiguous_claim ;;
esac

row=$(claims_unit_row "$ROWS" "$unit")
[ -n "$row" ] || refuse no_such_claim
BRANCH=$(printf '%s' "$row" | awk -F'\t' '{print $2}')
verdict=$(printf '%s' "$row" | awk -F'\t' '{print $7}')

# THE PROOF GATE. Nothing but `superseded` reaches the three acts.
if [ "$verdict" != "superseded" ]; then
    if [ -n "$UNANSWERED_FILE" ] && [ -f "$UNANSWERED_FILE" ] \
        && awk -F'\t' -v b="$BRANCH" '$1 == b { found = 1 } END { exit found ? 0 : 1 }' "$UNANSWERED_FILE"; then
        why=$(awk -F'\t' -v b="$BRANCH" '$1 == b { print $2; exit }' "$UNANSWERED_FILE")
        refuse "unanswerable:${why:-unreadable}"
    fi
    refuse "not_superseded:${verdict}"
fi

# --- Act 1: close the pull request -------------------------------------------------------
PR_STATE="unknown"
# `available` EXITS 0 EVEN WHEN IT ANSWERS `ok: false`, so the field is what is read here.
# Keying on the exit status would have called an absent `gh` available and sent the close
# straight into a transport that is not there.
if [ ! -f "$GH_REST" ] || ! sh "$GH_REST" available 2>/dev/null | grep -q '"ok": true'; then
    PR_STATE="failed"
    pr_note="gh_unavailable"
else
    SLUG=$(sh "$GH_REST" slug 2>/dev/null || true)
    if [ -z "$SLUG" ]; then
        PR_STATE="failed"
        pr_note="slug_unresolved"
    else
        OWNER=${SLUG%%/*}
        # `state=all`: an ALREADY-CLOSED pull request must read `already_closed`, not `none`.
        # Those are different facts — the second would send a reader looking for a pull request
        # that does exist.
        pr_json=$(sh "$GH_REST" api "repos/${SLUG}/pulls?head=${OWNER}:${BRANCH}&state=all&per_page=1" 2>/dev/null || true)
        PR=$(printf '%s' "$pr_json" | jq -r '.[0].number // ""' 2>/dev/null || printf '')
        pr_state_now=$(printf '%s' "$pr_json" | jq -r '.[0].state // ""' 2>/dev/null || printf '')
        if [ -z "$PR" ]; then
            PR_STATE="none"
            pr_note=""
        elif [ "$pr_state_now" != "open" ]; then
            PR_STATE="already_closed"
            pr_note=""
        elif sh "$GH_REST" api "repos/${SLUG}/pulls/${PR}" --method PATCH -f state=closed >/dev/null 2>&1; then
            PR_STATE="closed"
            pr_note=""
        else
            PR_STATE="failed"
            pr_note="pull_request_close_failed"
        fi
    fi
fi

# --- Act 2: delete the remote branch -----------------------------------------------------
if ! git rev-parse --verify --quiet "refs/remotes/origin/${BRANCH}" >/dev/null 2>&1; then
    REMOTE_STATE="already_gone"
elif git push --quiet origin --delete "$BRANCH" >/dev/null 2>&1; then
    REMOTE_STATE="deleted"
else
    # Measured 2026-08-05 on the hourly runner: a cloud container may PUSH but not DELETE a
    # branch. Named rather than fatal — the other two acts stand on their own.
    REMOTE_STATE="failed"
fi

# --- Act 3: reap the worktree ------------------------------------------------------------
worktree_path="${repo_root}/.worktrees/${unit}"
if [ ! -d "$worktree_path" ]; then
    WORKTREE_STATE="absent"
elif cleanup_out=$( ( cd "$repo_root" && sh "$CLEANUP" "$unit" ) 2>/dev/null ); then
    case "$cleanup_out" in
        *'"worktree_removed": true'*) WORKTREE_STATE="reaped" ;;
        *)                            WORKTREE_STATE="refused" ;;
    esac
else
    # The sanctioned cleaner refuses a dirty worktree and must: uncommitted work is never
    # discarded here, whatever the claim's verdict says about the branch.
    WORKTREE_STATE="refused"
fi

# `retired` is the whole retirement, and a partial one says so. Each act's own word is already
# on the row above, so the caller reports WHAT happened rather than that something did.
if [ "$PR_STATE" = "failed" ] || [ "$REMOTE_STATE" = "failed" ] || [ "$WORKTREE_STATE" = "refused" ]; then
    report false "${pr_note:-partial_retirement}"
fi
report true ""
