#!/bin/sh -eu
# WHO HOLDS THE UNIT THIS BRANCH IS DRIVING? A pure read, composed entirely from
# `lib/claims.sh` -- no second oracle, no new verdict word, and nothing written anywhere.
#
#   claim-holder.sh <branch>
#
# Output: one JSON line, always exit 0.
#   {"ok": true, "branch": "...", "unit": "...", "holder": "mine|other|ambiguous|unknown",
#    "holder_branch": "...", "branches": "...", "fetched": bool, "reason": "..."}
#
# WHY IT EXISTS (2026-08-30, mission `stop-two-runs-from-claiming-and-driving-one-unit`).
# The claim protocol closes the window between two SURVEYS. It does not close the window
# between a survey and the first WRITE: a runner can hold a claim, begin driving, and only
# later meet a state its claim no longer covers -- another runner's fresh claim over a
# `superseded` branch, a release, a retirement, or a race the survey could not see. The
# measured cost of noticing that late is an hour of duplicated implementation; the cost of
# noticing it at the first archive write is one survey.
#
# ITS ONE CONSUMER IS `archive.sh`, at the seam where a driving run FIRST WRITES SOMETHING
# THE BASE WILL SEE. It is enumerated in `drive/reference/claims.md`, *When a bounded act may
# read a judgement*, and every clause of that rule is met there: the reading is re-derived at
# the moment of the write, the refusal writes nothing, and the archive it gates is a commit
# on the claim branch rather than a rewrite of anything.
#
# THE BIAS IS THE OPPOSITE OF THE CLAIM ACT'S, AND DELIBERATELY SO. `claim.sh` refuses
# without a reachable origin, because an unpublished claim is not a claim. Here a wrong
# refusal STRANDS FINISHED WORK outside the archive, needing the hand-written `git mv` the
# drive workflow forbids -- so this answers `other` only on POSITIVE EVIDENCE that a
# different live branch now holds the unit, and everything else (an unreadable scan, an
# unreachable origin, no claim row for this branch at all) answers `unknown`, which its
# consumer reads as *proceed*.
#
# THE MERGED-PULL-REQUEST LOOKUP IS OFF, by the env var that already exists for it. This
# reading compares BRANCH IDENTITY and never asks whether a unit is finished, so the one
# verdict the lookup can change (`superseded` at the mission grain) cannot move the answer
# -- and `archive.sh` runs once per ticket, where a REST call per claim per ticket is a cost
# with nothing to buy. Since 2026-08-30 the mission grain answers `superseded` from the tree
# anyway, so a raced twin is still seen without it.
#
# `ambiguous` IS REPORTED, NEVER PICKED BETWEEN, exactly as everywhere else in the protocol:
# two live claims for one unit is the race itself, and it is the state this reading exists
# to catch before a duplicate reaches the base.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

BRANCH="${1:-}"

emit() { # holder, unit, holder_branch, branches, fetched, reason
    printf '{"ok": true, "branch": "%s", "unit": "%s", "holder": "%s", "holder_branch": "%s", "branches": "%s", "fetched": %s, "reason": "%s"}\n' \
        "$BRANCH" "$2" "$1" "$3" "$4" "$5" "$6"
    exit 0
}

if [ -z "$BRANCH" ]; then
    printf '{"ok": false, "reason": "usage", "detail": "claim-holder.sh <branch>"}\n'
    exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    emit unknown "" "" "" false not_a_repo
fi

# The lookup is disabled for this reading (see the header). It is set for the whole process
# rather than per call because `claims_scan` reaches it indirectly.
WORKAHOLIC_CLAIM_MERGED_LOOKUP=0
export WORKAHOLIC_CLAIM_MERGED_LOOKUP

fetched=$(claims_fetch)
# `claims_fetch` ran in a command substitution, so the flag it set died with that subshell.
# It is restated here for the same reason `claim.sh` and `release-claim.sh` restate it --
# except that here the lookup is off regardless, so this only keeps the two readings honest
# if the opt-out above is ever removed.
CLAIMS_FETCH_OK="$fetched"
export CLAIMS_FETCH_OK

base=$(claims_base)
[ -n "$base" ] || emit unknown "" "" "" "$fetched" no_base

rows=$(claims_scan "$base")
[ -n "$rows" ] || emit unknown "" "" "" "$fetched" no_claims

# The unit THIS branch claims. A branch with no claim row is not evidence of anything: it is
# a branch whose claim commit has merged, a ref this clone has not fetched, or a hand-made
# branch. `unknown`, and the caller proceeds.
unit=$(printf '%s\n' "$rows" | awk -F'\t' -v b="$BRANCH" '$2 == b { print $1; exit }')
[ -n "$unit" ] || emit unknown "" "" "" "$fetched" no_row_for_branch

resolution=$(claims_unit_resolution "$rows" "$unit")
case "$resolution" in
    ambiguous)
        emit ambiguous "$unit" "" "$(claims_unit_live_branches "$rows" "$unit")" "$fetched" two_live_claims
        ;;
esac

holder_branch=$(claims_unit_row "$rows" "$unit" | cut -f2)
# `claims_unit_row` is empty for `none` and `ambiguous`; `none` is unreachable here (this
# branch's own row was just read out of the same scan) and `ambiguous` returned above, so an
# empty value at this point is a reading we could not make rather than a takeover.
[ -n "$holder_branch" ] || emit unknown "$unit" "" "" "$fetched" "unresolved:${resolution}"

if [ "$holder_branch" = "$BRANCH" ]; then
    emit mine "$unit" "$holder_branch" "" "$fetched" ""
fi
emit other "$unit" "$holder_branch" "" "$fetched" "held_by:${holder_branch}"
