#!/bin/sh -eu
# Has the CI executor had its turn at the branches this repository's claim oracle proved empty?
#
# Usage: ci-retirement-turn.sh
# Output: {"readable": bool, "reason": "", "ci_turn": "taken"|"pending"|"unavailable",
#          "base_sha": "..."}
#         Always exit 0.
#
# WHY IT EXISTS (2026-08-28, mission `finish-a-proved-retirement-where-the-write-is-permitted`).
# `/moderate`'s `retire-claims` step asks the claim holder to delete a branch the container was
# refused (`retire-blocked:<unit>`). Once CI takes that act the question must fire only for what
# CI COULD NOT TAKE EITHER — otherwise a person is asked, once per unit and forever, for an act a
# workflow was about to perform, and the ask is not merely noisy but WRONG.
#
# THE READING IS STORE-FREE, WHICH IS THE CONSTRAINT THAT SHAPED IT. No cursor, no queue, no
# field on any artifact, no second ledger. It rests on a fact the two sides already produce:
# `claim-retirement.yml` DELETES the branch when it succeeds, and unmerged remote branches are
# the only claim oracle — so a successful CI turn removes the claim row itself and the candidate
# with it. A superseded branch that is STILL THERE therefore means one of exactly two things, and
# this answers which:
#
#   taken        a COMPLETED run exists at the base tip the tick is reading. CI has seen exactly
#                this tree and the branch survived it, so CI refused too — the unit is genuinely
#                blocked and its holder is the person who can act.
#   pending      no completed run at this tip yet (the push is in flight, or the run is still
#                running). CI may still delete the branch, so nobody is asked this tick. The
#                question is DELAYED, never dropped: the asked-once ledger keys on the unit, so a
#                later tick asks it if the branch outlives CI's turn.
#   unavailable  the workflow is not present in this repository at all, so CI will never take the
#                act. The unit is blocked exactly as it was before this reading existed.
#
# THE TIP IS THE COMPARISON, NOT A TIMESTAMP. Matching `head_sha` against the base the tick is
# reading needs no clock, no timezone and no date parsing, and it answers the question actually
# being asked — *did CI see THIS tree* — rather than a proxy for it. A run created after the
# branch's own last commit is not the same fact: a claim becomes superseded when the BASE moves,
# which can happen long after the branch tip stopped moving.
#
# A DEGRADED READ IS NAMED AND NEVER SILENTLY ANSWERS `pending`. The caller's rule is the
# ticket's own: an over-eager question is better than a silently dropped one, and this repository
# has measured the cost of a blocked act nobody was told about. So `readable: false` leaves the
# question exactly where it was before this narrowing existed.
#
# IT IS A PURE READ: no file, no commit, no branch, no delete, and one bounded GitHub read.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"

# The workflow whose runs answer the question. Named once, here.
WORKFLOW_FILE="claim-retirement.yml"

BASE_SHA=""

emit() {
    printf '{"readable": %s, "reason": "%s", "ci_turn": "%s", "base_sha": "%s"}\n' \
        "$1" "$2" "$3" "$BASE_SHA"
    exit 0
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || emit false not_a_repository pending
BASE_SHA=$(git rev-parse --verify --quiet origin/main 2>/dev/null || printf '')
[ -n "$BASE_SHA" ] || emit false no_base pending

if [ ! -f "$GH_REST" ] || ! sh "$GH_REST" available 2>/dev/null | grep -q '"ok": true'; then
    emit false gh_unavailable pending
fi
SLUG=$(sh "$GH_REST" slug 2>/dev/null || true)
[ -n "$SLUG" ] || emit false slug_unresolved pending

runs=$(sh "$GH_REST" api \
    "repos/${SLUG}/actions/workflows/${WORKFLOW_FILE}/runs?status=completed&per_page=30" 2>/dev/null || true)

# A 404 from the workflow endpoint is the `unavailable` reading, not a degradation: the answer
# ("CI will never take this act here") is definite, and a repository that has not adopted the
# workflow must keep getting the question it got before.
if [ -z "$runs" ]; then
    emit true workflow_unreachable unavailable
fi
if ! printf '%s' "$runs" | jq -e 'has("workflow_runs")' >/dev/null 2>&1; then
    emit true workflow_absent unavailable
fi

if printf '%s' "$runs" | jq -e --arg sha "$BASE_SHA" \
    '[.workflow_runs[]? | select(.head_sha == $sha)] | length > 0' >/dev/null 2>&1; then
    emit true "" taken
fi

emit true "" pending
