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
#         `reason` is a CLOSED VOCABULARY, empty on a complete retirement. A refusal before the
#         acts: `not_a_repository`, `no_origin`, `origin_unreachable`, `no_claims`,
#         `no_such_claim`, `ambiguous_claim`, `unanswerable:<why>`, `not_superseded:<verdict>`.
#         A blocked act names ITS OWN act (2026-08-27): `gh_unavailable` / `slug_unresolved` /
#         `pull_request_close_failed` for the close, `branch_delete_failed` for the delete,
#         `worktree_reap_refused` for the reap. `partial_retirement` is retired — it collapsed
#         all three into one word.
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
# from the base's own history and from any local clone's reflog; the worktree is local and
# `claim.sh resume` rebuilds one at a branch tip. None of the three destroys work. That is a
# property of acting only on the proof, not a licence to widen the verdict set.
#
# THE RECOVERY ABOVE RESTS ON TWO SEPARATE PROOFS, AND SAYING SO IS NOT PEDANTRY (2026-09-01,
# issue #788). Until then this comment read "*its content is on the base — that is what
# `superseded` means*", and that parenthesis was the load-bearing half of the whole safety
# argument. It was FALSE. `superseded` proved one thing and the recovery claimed another:
#
#   * THE TICKETS ARE ARCHIVED ON THE BASE — proved by `claims_archived_on_base` at the batch
#     grain, `claims_mission_landed` / the merged-pull-request lookup at the mission grain.
#   * THE BRANCH HOLDS NO WORK — proved by `claims_branch_empty_against_base`, one `merge-base`
#     and one `diff --quiet` (`lib/claims.sh`).
#
# Neither implies the other. The step from the first to the second holds only when a branch
# carries nothing but its own unit's tickets, and the measured branches did not: two of them,
# whose tickets had landed through DIFFERENT branches, still held ~300 lines of code and a
# documentation section present on no other ref, and this act was being asked to delete both.
#
# THE 403 IS PART OF THE RECORD, HONESTLY. The delete has never actually run against those
# branches — a session-type refusal on `push --delete` had been failing it for five days — so
# the loss is a NEAR MISS rather than a history, and the tick was reporting that refusal as the
# problem. Which is exactly why the derivation had to be repaired first: repairing the transport
# alone would have turned a reported nuisance into a silent loss on the first tick after the fix.
#
# THE SECOND PROOF IS NOW A TERM OF THE VERDICT, so the recovery sentence above is true by
# construction rather than by hope, and an unanswerable emptiness answers `stranded` instead —
# it does not license this act at all. Do not remove the diff term as redundant with the archive
# test: they answer different questions, and this comment is the record of what it cost to
# discover that.
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
    # MEASURED, NOT ASSUMED (2026-08-27, mission `finish-the-retirement-the-loop-cannot-complete`;
    # the 2026-08-05 note here was a hypothesis and is now a measurement). Reproduced in a
    # routine-fired container against a claim already proved `superseded` on this repository:
    #
    #   git push origin --delete   →  error: RPC failed; HTTP 403 curl 22 The requested URL
    #                                 returned error: 403
    #   DELETE /repos/{o}/{r}/git/refs/heads/{branch} through `gh-rest.sh`
    #                              →  HTTP 403 {"message":"Write access to this GitHub API path
    #                                 is not permitted through this proxy."}
    #
    # The two transports AGREE, and the refusal is a SESSION-TYPE one: not a protection rule
    # (which answers 422 naming the rule) and not a missing scope (which answers a permissions
    # message). An ordinary `git push` of this same branch succeeds in this same container, so
    # it is the delete specifically that is refused.
    #
    # NO SECOND TRANSPORT IN THIS CONTAINER CAN TAKE THIS ACT, and that is the recorded finding
    # rather than a gap: REST is refused above, and the GitHub connector exposes `create_branch`
    # and `list_branches` but NO branch- or ref-delete surface at all — so there is nothing for a
    # `rules/shell.md`-style bounded retry to attempt, here or in the caller. A second REST
    # attempt is deliberately NOT made: it is measured to answer 403, and a call that cannot
    # succeed is noise with a cost.
    #
    # A DIFFERENT EXECUTOR TAKES IT INSTEAD (2026-08-28, mission
    # `finish-a-proved-retirement-where-the-write-is-permitted`). The finding above is about the
    # CONTAINER and stays exactly as measured; what changed is that the act no longer has to
    # happen here. `.github/workflows/claim-retirement.yml` holds `contents: write` and runs
    # `delete-retired-claim-branch.sh`, which re-proves the verdict at the moment of the act and
    # bounds it — the same shape `release-note-draft.yml` already gave the release-note write.
    # THIS SCRIPT IS UNCHANGED BY THAT: it still attempts its own delete (the container is where
    # a retirement starts, and a repository that has not adopted the workflow must keep getting
    # the honest refusal), and `branch_delete_failed` still means what it always did. Full
    # record: `../reference/claims.md`, *When an act of the retirement is refused*.
    #
    # Named rather than fatal — the other two acts stand on their own, the closing branch
    # reports `branch_delete_failed` so the reader learns WHICH act is blocked, and the caller
    # renders the acts that succeeded beside it. What follows the refusal is CI's turn, and only
    # if the branch survives that too does a person get asked.
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

# `retired` is the whole retirement, and a partial one says WHICH ACT IS BLOCKED (2026-08-27,
# mission `finish-the-retirement-the-loop-cannot-complete`). This branch reported
# `partial_retirement` for all three failures until then, so a refused pull-request close, a
# refused branch delete and a dirty worktree read alike and only the first had a `pr_note` that
# survived — measured on this repository, three units reported `partial_retirement` for a BRANCH
# DELETE and nothing in the tick log said so. This is the `session_type_cannot_merge` precedent
# (2026-08-23) one act over: a refusal the transport made gets its own word, so the reader learns
# which act is blocked rather than that something was.
#
# THE WORD IS DERIVED FROM THE THREE STATES ALREADY ON THE ROW — no new field, no second
# derivation — and the acts are consulted in ACT ORDER, so the reason names the first blocked
# act while the row's three states show every one of them (which is what the caller renders).
#
# ONE WORD PER ACT, NOT THREE PER CAUSE. The refusal was measured before this was written
# (2026-08-27, in a routine-fired container): both transports answer 403 — `git push --delete`
# gets `RPC failed; HTTP 403` and the REST endpoint answers *"Write access to this GitHub API
# path is not permitted through this proxy."* — so the world here has ONE cause, a session-type
# refusal, and a speculative protection-rule/missing-scope/session-type split would ship three
# words for it. The message belongs in a diagnosis; the reason stays a closed vocabulary the
# caller can key on.
#
# EVERY SUCCESS WORD IS UNTOUCHED: `already_closed`, `already_gone`, `none` and `absent` are
# successes, not degradations, and a fully successful retirement still reports `retired: true`
# with an empty reason.
if [ "$PR_STATE" = "failed" ]; then
    report false "${pr_note:-pull_request_close_failed}"
elif [ "$REMOTE_STATE" = "failed" ]; then
    report false branch_delete_failed
elif [ "$WORKTREE_STATE" = "refused" ]; then
    report false worktree_reap_refused
fi
report true ""
