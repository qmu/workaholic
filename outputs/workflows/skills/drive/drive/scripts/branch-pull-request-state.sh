#!/bin/sh -eu
# What became of THIS BRANCH's pull request? One reader, keyed on a branch name, answering
# exactly that and nothing else.
#
# WHY IT IS A SECOND QUESTION AND NOT A WIDENING OF `claim-merged.sh` (2026-09-01, mission
# `leave-only-live-work-in-the-unmerged-branch-list`). That reader is keyed on a UNIT and
# answers whether the unit's CONTENT reached the base — its three-valued `state`
# (`merged` / `not_merged` / `unanswerable`) feeds a claim verdict, and its `pr_state` rides
# along as a description of the pull request it happened to read. This one is keyed on a
# BRANCH and answers what became of that branch's pull request, which is the question a
# retirement candidate is proved from. Merging them would give two callers one answer: a
# consumer asking "may this branch be deleted" would inherit a field shaped for "is this unit
# still in flight", and the first wrong reading deletes a branch.
#
# IT IS A READER AND NEVER A VERDICT. It names no candidate, fires no act, moves no claim
# verdict and writes nothing anywhere. Putting the proof and the act in one script is the
# shape `retire-claim.sh`'s own header refuses, and the tickets that consume this answer add
# the candidate readings above it.
#
# FOUR STATES, AND `none` IS A FACT RATHER THAN A DEGRADATION:
#
#   merged           some pull request for this head has a non-null `merged_at`
#   closed_unmerged  the newest one is closed with `merged_at` null
#   open             the newest one is open
#   none             the lookup SUCCEEDED and found no pull request at all
#
# AN UNREADABLE TRANSPORT EMITS NO `state` KEY AT ALL. `ok: false` plus a named reason, and
# never `none` — a caller reading `none` is entitled to treat it as *provably no pull
# request*, which is exactly the licence a degraded read must not hand out. This is the
# asymmetry `claim-merged.sh` spends its longest comment on, applied one question over: a
# wrong `merged`/`closed_unmerged` DELETES a branch, a wrong `ok: false` only makes a caller
# wait.
#
# IT EXITS 0 IN EVERY CASE, INCLUDING EVERY DEGRADATION, so a caller's scan is never turned
# into a failed scan by a reading it could have reported.
#
# BOUNDED EXACTLY AS `claim-merged.sh` IS. At most one network read per invocation; no ref,
# worktree, cursor or field on any artifact; and skipped BY NAME whenever it cannot succeed —
# `WORKAHOLIC_CLAIM_MERGED_LOOKUP=0` is the same explicit opt-out (one variable for the
# protocol's network reads, not one per reader), and a caller inside a claim scan whose fetch
# already failed sets `CLAIMS_FETCH_OK=false`, which is proof there is no network and is
# reported `offline` rather than spent. `CLAIMS_FETCH_OK` UNSET means the caller is outside a
# scan and says nothing about the network, so it is not read as offline.
#
# THE NEWEST PULL REQUEST WINS when a branch has several, ordered by `created_at`, with one
# exception in the same spirit as `claim-merged.sh`'s: a MERGED one wins outright, because a
# branch whose work reached the base is answered by that fact whatever was opened afterwards.
# A branch reused across two pull requests is rare, and picking silently is how a reader
# drifts — so the order is written here rather than left to the API's.
#
# Usage: branch-pull-request-state.sh <branch-name>
# Output: one JSON line
#   {"ok": true,  "branch", "number": <n>|null, "state": "merged|closed_unmerged|open|none", "reason": ""}
#   {"ok": false, "branch", "number": null, "reason": "<named>"}      — no "state" key

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"

BRANCH="${1:-}"

# $1 state, $2 number (JSON)
emit_ok() {
    printf '{"ok": true, "branch": "%s", "number": %s, "state": "%s", "reason": ""}\n' \
        "$BRANCH" "${2:-null}" "$1"
    exit 0
}

# $1 reason. Deliberately emits NO "state" key — see the header.
emit_unreadable() {
    printf '{"ok": false, "branch": "%s", "number": null, "reason": "%s"}\n' "$BRANCH" "$1"
    exit 0
}

[ -n "$BRANCH" ] || emit_unreadable no_branch
[ -f "$GH_REST" ] || emit_unreadable no_transport_script

[ "${WORKAHOLIC_CLAIM_MERGED_LOOKUP:-1}" = "0" ] && emit_unreadable disabled

# Set and not `true` means a caller's own fetch already failed. Unset means no caller has an
# opinion, which is not evidence of anything.
if [ -n "${CLAIMS_FETCH_OK+x}" ] && [ "${CLAIMS_FETCH_OK}" != "true" ]; then
    emit_unreadable offline
fi

# NO SEPARATE AVAILABILITY PROBE, for `claim-merged.sh`'s reason: the probe would double the
# network cost to learn what the call itself reports, and classifying the one call's failure
# is the only classification that stays honest when the transport dies between the two.
slug=$(sh "$GH_REST" slug 2>/dev/null || true)
case "$slug" in
    */*) ;;
    *) emit_unreadable slug_unresolved ;;
esac
owner="${slug%%/*}"

# REPOSITORY-SCOPED AND FILTERED LOCALLY: a bound session refuses `search/*`
# (`rules/shell.md`), so the lookup is the `pulls` collection narrowed by `head`, which the
# REST API supports as `<owner>:<branch>`. `state=all` is what lets `open`, `closed_unmerged`
# and `none` be told apart at all.
if ! body=$(sh "$GH_REST" api \
        "repos/${slug}/pulls?state=all&head=${owner}:${BRANCH}&per_page=50" 2>&1); then
    case "$body" in
        *"not on PATH"*) emit_unreadable gh_unavailable ;;
        *"rate limit"*|*"rate_limit"*|*"API rate"*) emit_unreadable rate_limited ;;
        *"not enabled for this session"*|*"not permitted for this session"*)
            emit_unreadable session_refused ;;
        *) emit_unreadable transport_error ;;
    esac
fi

# An unparseable body is OURS, and is never evidence that the branch has no pull request.
printf '%s' "$body" | jq -e 'type == "array"' >/dev/null 2>&1 || emit_unreadable unparseable_response

row=$(printf '%s' "$body" | jq -c '
    (   ([.[] | select(.merged_at != null)] | sort_by(.merged_at)  | last)
     // ([.[] | select(.merged_at == null)] | sort_by(.created_at) | last)
    ) // empty' 2>/dev/null || true)

# THE LOOKUP SUCCEEDED AND THERE IS NO PULL REQUEST. A fact about the repository.
[ -n "$row" ] || emit_ok none null

number=$(printf '%s' "$row" | jq '.number // null' 2>/dev/null || echo null)
case "$number" in '') number=null ;; esac

merged_at=$(printf '%s' "$row" | jq -r '.merged_at // "null"' 2>/dev/null || printf 'null')
if [ "$merged_at" != "null" ]; then
    emit_ok merged "$number"
fi

pr_state=$(printf '%s' "$row" | jq -r '.state // ""' 2>/dev/null || printf '')
if [ "$pr_state" = "open" ]; then
    emit_ok open "$number"
fi
emit_ok closed_unmerged "$number"
