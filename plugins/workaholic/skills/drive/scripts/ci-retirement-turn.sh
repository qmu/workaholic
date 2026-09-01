#!/bin/sh -eu
# Has the CI executor had its turn at the branches this repository's claim oracle proved empty —
# and what did each act ANSWER?
#
# Usage: ci-retirement-turn.sh [<unit> ...]
# Output: {"readable": bool, "reason": "", "ci_turn": "taken"|"pending"|"unavailable"|"unreadable",
#          "base_sha": "...",
#          "units": [{"unit": "...", "ci_turn": "taken"|"refused:<word>"|"pending"|"unavailable"|"unreadable"}]}
#         Always exit 0.
#
# WHY IT EXISTS (2026-08-28, mission `finish-a-proved-retirement-where-the-write-is-permitted`).
# `/moderate`'s `retire-claims` step asks the claim holder to delete a branch the container was
# refused (`retire-blocked:<unit>`). Once CI takes that act the question must fire only for what
# CI COULD NOT TAKE EITHER — otherwise a person is asked, once per unit and forever, for an act a
# workflow was about to perform, and the ask is not merely noisy but WRONG.
#
# ---------------------------------------------------------------------------------------------
# THE PREMISE THIS READING WAS BUILT ON, AND WHY IT NO LONGER HOLDS (2026-08-29, mission
# `read-back-whether-the-loop-s-own-act-took-effect`). The sentence is corrected in place rather
# than deleted, because a later reader needs to see what was being answered:
#
#     "CI DELETES the branch when it succeeds, and unmerged remote branches are the only claim
#      oracle — so a successful CI turn removes the claim row and the candidate with it."
#
# That was the DESIGN and not the BEHAVIOUR. The inference it licensed — a completed run at the
# base tip means CI saw this tree and the branch survived it, therefore `taken` — is true only
# if every completed turn actually reached its act. Measured 2026-08-29 on this repository:
# `claim-retirement.yml` was green on every run while THREE proved-`superseded` claims stood on
# origin, and the tick log recorded, hour after hour, *"ci_turn: taken so CI could not take the
# delete either"* — an assertion about a second executor that NOTHING ESTABLISHED. (The live
# cause, localized the same day: the CI-side act refuses `gh_unavailable` before its proof gate,
# because `gh-rest.sh available` probes `gh api user`, which a `GITHUB_TOKEN` installation token
# cannot call.)
#
# WHAT REPLACED IT: the turn now RECORDS what it attempted and what each act answered
# (`record-ci-retirement-turn.sh`, read back through `read-ci-retirement-record.sh`), and this
# script answers from that record. `taken` is claimed only on the act's own success word — never
# on a run's existence, and never on its exit status, which is green by design because a refusal
# must not fail the job.
#
# THE STORE-FREE ARGUMENT IS NARROWED, NOT ABANDONED. Nothing here stores anything: no cursor,
# no queue, no ledger, no field on any artifact. What changed is only WHICH PART of the run is
# consulted — its recorded answer instead of its existence. The record rides the run the tick is
# already reading, so this remains one bounded read of a fact the two sides already produce.
# ---------------------------------------------------------------------------------------------
#
# THE PER-UNIT VOCABULARY:
#
#   taken            the act answered a SUCCESS for this unit (`deleted`, or `already_gone` —
#                    the branch was not there when CI looked, which is the same outcome).
#   refused:<word>   the act answered a refusal, carrying `delete-retired-claim-branch.sh`'s OWN
#                    word verbatim; or the turn's CANDIDATE READING was degraded and named its
#                    reason, in which case that reason is carried instead. Never a third
#                    vocabulary: a reader must be sent to a word some script actually printed.
#   pending          no completed run at this tip yet (the push is in flight, or the run is
#                    still running). CI may still delete the branch, so nobody is asked this
#                    tick. The question is DELAYED, never dropped: the asked-once ledger keys on
#                    the unit, so a later tick asks it if the branch outlives CI's turn.
#   unavailable      the workflow is not present in this repository at all, so CI will never
#                    take the act. The unit is blocked exactly as it was before this reading
#                    existed.
#   unreadable       a run completed but its record is absent, unparseable, past its truncation
#                    bound, or simply names this unit nothing while the candidate reading itself
#                    was fine. We cannot say what happened, so we say that.
#
# ONLY `taken` AND `pending` HOLD THE QUESTION. `refused:<word>` is precisely the case a person
# must hear about, and `unreadable` keeps this script's founding discipline: an over-eager
# question is better than a silently dropped one, and this repository has measured the cost of a
# blocked act nobody was told about.
#
# THE TIP IS THE COMPARISON, NOT A TIMESTAMP. Matching `head_sha` against the base the tick is
# reading needs no clock, no timezone and no date parsing, and it answers the question actually
# being asked — *did CI see THIS tree* — rather than a proxy for it. A run created after the
# branch's own last commit is not the same fact: a claim becomes superseded when the BASE moves,
# which can happen long after the branch tip stopped moving.
#
# IT IS A PURE READ: no file, no commit, no branch, no delete, and a few bounded GitHub reads.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"
RECORD_READER="${SCRIPT_DIR}/read-ci-retirement-record.sh"

# The workflow whose runs answer the question. Named once, here.
WORKFLOW_FILE="claim-retirement.yml"

BASE_SHA=""

# Every unit asked about, answered with one run-level word. Used for every path that resolves
# before a per-unit record can be consulted — a degraded read, a missing workflow, a tip with no
# completed run — so a caller always gets an entry per unit it named.
units_all() {
    _ua_word="$1"; shift
    _ua_out=""; _ua_sep=""
    for _ua_u in "$@"; do
        [ -n "$_ua_u" ] || continue
        _ua_out="${_ua_out}${_ua_sep}{\"unit\": \"${_ua_u}\", \"ci_turn\": \"${_ua_word}\"}"
        _ua_sep=", "
    done
    printf '%s' "$_ua_out"
}

emit() {
    printf '{"readable": %s, "reason": "%s", "ci_turn": "%s", "base_sha": "%s", "units": [%s]}\n' \
        "$1" "$2" "$3" "$BASE_SHA" "${4:-}"
    exit 0
}

UNITS="$*"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || emit false not_a_repository pending "$(units_all pending $UNITS)"
BASE_SHA=$(git rev-parse --verify --quiet origin/main 2>/dev/null || printf '')
[ -n "$BASE_SHA" ] || emit false no_base pending "$(units_all pending $UNITS)"

if [ ! -f "$GH_REST" ] || ! sh "$GH_REST" available 2>/dev/null | grep -q '"ok": true'; then
    emit false gh_unavailable pending "$(units_all pending $UNITS)"
fi
SLUG=$(sh "$GH_REST" slug 2>/dev/null || true)
[ -n "$SLUG" ] || emit false slug_unresolved pending "$(units_all pending $UNITS)"

runs=$(sh "$GH_REST" api \
    "repos/${SLUG}/actions/workflows/${WORKFLOW_FILE}/runs?status=completed&per_page=30" 2>/dev/null || true)

# A 404 from the workflow endpoint is the `unavailable` reading, not a degradation: the answer
# ("CI will never take this act here") is definite, and a repository that has not adopted the
# workflow must keep getting the question it got before.
if [ -z "$runs" ]; then
    emit true workflow_unreachable unavailable "$(units_all unavailable $UNITS)"
fi
if ! printf '%s' "$runs" | jq -e 'has("workflow_runs")' >/dev/null 2>&1; then
    emit true workflow_absent unavailable "$(units_all unavailable $UNITS)"
fi

# NO COMPLETED RUN AT THIS TIP IS `pending`; A RUN WE CANNOT IDENTIFY IS `unreadable`. The two
# are separated deliberately, because only `pending` holds a question: answering it for a run
# that DID complete and whose record we simply could not reach would suppress the ask on our own
# degradation, which is the shape this whole reading exists to remove.
MATCHED=$(printf '%s' "$runs" | jq -r --arg sha "$BASE_SHA" \
    '[.workflow_runs[]? | select(.head_sha == $sha)] | length' 2>/dev/null || printf '0')
[ "$MATCHED" -gt 0 ] 2>/dev/null || emit true "" pending "$(units_all pending $UNITS)"

RUN_ID=$(printf '%s' "$runs" | jq -r --arg sha "$BASE_SHA" \
    '[.workflow_runs[]? | select(.head_sha == $sha) | .id] | first // ""' 2>/dev/null || printf '')
[ -n "$RUN_ID" ] || emit true no_run_id unreadable "$(units_all unreadable $UNITS)"

# --- The record ---------------------------------------------------------------------------
# One reader, composed rather than re-implemented here: which surface the turn records onto is
# that script's knowledge, and duplicating the parse is how two readings of one fact drift.
record=""
[ -f "$RECORD_READER" ] && record=$(sh "$RECORD_READER" "$RUN_ID" 2>/dev/null || true)
if [ -z "$record" ] || ! printf '%s' "$record" | jq -e '.ok // false' >/dev/null 2>&1; then
    # A run completed and we cannot see what it did. That is `unreadable` and it suppresses
    # nothing — the one answer the retired inference refused to give.
    why=$(printf '%s' "$record" | jq -r '.reason // "record_unreadable"' 2>/dev/null || printf 'record_unreadable')
    emit true "${why}" unreadable "$(units_all unreadable $UNITS)"
fi

# The turn's own candidate reading. A degraded one names its reason, and that reason is what a
# unit the record never mentions is answered with — the turn could not consider it, and it says
# why. A HEALTHY reading that simply never named the unit yields `unreadable` instead: nothing
# went wrong that we can name, and we still cannot say what happened to this unit.
cand_ok=$(printf '%s' "$record" | jq -r '.candidates_ok // false')
cand_reason=$(printf '%s' "$record" | jq -r '.candidates_reason // ""')
if [ "$cand_ok" = "true" ] || [ -z "$cand_reason" ]; then
    unnamed="unreadable"
else
    unnamed="refused:${cand_reason}"
fi

units=""
sep=""
for u in $UNITS; do
    [ -n "$u" ] || continue
    row=$(printf '%s' "$record" | jq -c --arg u "$u" \
        '[.acts[]? | select(.unit == $u)] | first // empty' 2>/dev/null || printf '')
    if [ -z "$row" ]; then
        word="$unnamed"
    else
        state=$(printf '%s' "$row" | jq -r '.state // ""')
        reason=$(printf '%s' "$row" | jq -r '.reason // ""')
        case "$state" in
            deleted|already_gone) word="taken" ;;
            *) word="refused:${reason:-${state:-unstated}}" ;;
        esac
    fi
    units="${units}${sep}{\"unit\": \"${u}\", \"ci_turn\": \"${word}\"}"
    sep=", "
done

# THE RUN-LEVEL WORD MEANS *CI HAD ITS TURN AND WE CAN SEE WHAT IT DID*, which is what `taken`
# should always have meant. It is never on its own a statement that any act succeeded: that is
# the per-unit answer, and it is the only thing a consumer may suppress a question on.
emit true "" taken "$units"
