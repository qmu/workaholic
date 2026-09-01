#!/bin/sh -eu
# Step — the conflict the loop looked at and must not resolve.
#
# WHY THIS STEP EXISTS (2026-08-29, mission
# `land-the-loop-s-own-work-when-the-base-moves-under-it`). `catch-up-claim.sh` brings a
# finished unit back onto a base that moved under it, and refuses `content_conflict` when the
# collision is one only a person can judge. That refusal reached nobody: `/implement` may not
# ask, and no step of this tick saw the shape.
#
# A BRANCH NOTHING HAS ATTEMPTED IS NOT THIS QUESTION, and that is the whole point of the
# split. `step-merge-conflicts.sh` reports a pull request GitHub calls conflicted — *nobody has
# looked yet* — and this asks about a branch the shared classification rule examined and
# declared a person's — *the loop looked and only you can decide*. Those ask somebody for
# different things, and one word for both is how four conflicted pull requests went unread for
# three days. So the candidate set is the READING (`mergeability: content`), never the pull
# request's own `mergeable: false`.
#
# WHICH SIBLING IT FOLLOWS, ON EACH AXIS:
#
#   whose question           `undelivered-units`'. The claim HOLDER drove this unit and is the
#                            person who knows which side of the conflict keeps its behaviour —
#                            which is the same reason `step-merge-conflicts.sh` gives for
#                            reporting to the holder rather than rebasing.
#   running identity         `undrivable-units`'. Never consulted. A branch that no longer
#                            merges is a fact about the repository, so an hourly question that
#                            depended on which container asked it would answer differently per
#                            account.
#   what it may read         `undrivable-units`'. `list-claims.sh` is a pure read;
#                            `plan-units.sh` is REFUSED, because the survey reaches the mission
#                            readers, which carry the living migrations and STAGE what they
#                            converge.
#
# ONE UNIT NEVER DRAWS TWO QUESTIONS. The candidate set is bounded to a unit that is FINISHED
# AND WAITING — `report_undelivered` or `queue_drained` — because that is the set nothing else
# will move: its queue is drained, its pull request is open, and a merge retry cannot help a
# branch the base no longer accepts. Everything else is somebody else's question already:
# `claim_active` and `heartbeat_lapsed` belong to the run driving or resuming the unit,
# `parked_with_pr` has work left whose own drive will meet the conflict, `awaiting_verification`
# draws `handoff-unit`, and `superseded` holds nothing at all. Beside it, `undelivered-units`
# FILTERS a `content` row out of its own candidates and counts it instead — one step asks and
# the other counts, exactly as `handoff-units` and `stalled-units` divide the same way, and
# either half alone is a defect: *retry your merge* is the wrong instruction for a branch that
# no longer merges.
#
# AND A UNIT THE RUN JUST CAUGHT UP NEEDS NO FILTER — MEASURED, 2026-08-30, mission
# `catch-a-reported-claim-up-before-its-conflict-hardens`. That mission widened `/implement`'s
# catch-up from `report_undelivered` alone to every REPORTED claim still `mechanical`, and asked
# whether this step must now filter out a unit the run had repaired, on the shape
# `stalled-units` uses for `awaiting_verification`. It must not, and the reason is worth
# recording so nobody re-opens it and adds a filter to have added one:
#
#   * THE TWO SETS ARE DISJOINT BY CONSTRUCTION. This step's candidates are
#     `mergeability == "content"`. Everything the run may catch up is `mechanical` —
#     `list-catchable-claims.sh` offers only that class, and `catch-up-claim.sh` refuses
#     `content_conflict` outright. A unit the run caught up was therefore never a candidate
#     here, so there is nothing to filter and nothing to count as filtered.
#   * AND THE READING SELF-CORRECTS ANYWAY. A caught-up branch contains the base, so
#     `claim-mergeability.sh` answers `clean` with `already_current: true` at the next read.
#     Even if a unit could move between the classes, it would leave this set on its own.
#
# So this step is BYTE-IDENTICAL across that widening: the key, the asked-once gate, the
# addressee, the per-tick cap, the holds and every other candidate are exactly what they were,
# and `ask-question.sh` gains nothing. The honest outcome of that ticket was a recorded finding
# and no change.
#
# THE CONFLICTED FILES RIDE THE CLAIM ROW. A question that cannot name what collided does not
# say what to look at, and reading the mergeability a second time here would be a second
# derivation of one fact — so `list-claims.sh` renders `mergeability_content_files` and this
# reads it.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, for the correctness reason
# `step-stalled-units.sh`'s header records: an incrementing summary makes the step "changed"
# hourly by construction and the root restates the same units all day.
#
# IT ASKS AND NOTHING ELSE: no merge, no rebase, no close, no claim touched, no gate lifted,
# and nothing written anywhere but its own tick-log line.
#
# Usage: step-catchup-blocked.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts"
# The claim library, for `claims_unit_resolution` alone — the raced-unit filter below reads the
# library's own single derivation rather than a second implementation of "two live claims".
CLAIMS_LIB_DIR="${DRIVE_SCRIPTS}/lib"
[ -f "${CLAIMS_LIB_DIR}/claims.sh" ] && . "${CLAIMS_LIB_DIR}/claims.sh"
. "${SCRIPT_DIR}/lib/raced-units.sh"

TICK=""
ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done
: "${TICK:?}"

emit() {
    printf '{"step": "catchup-blocked", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

lister="${DRIVE_SCRIPTS}/list-claims.sh"
[ -f "$lister" ] || emit degraded no_claim_reader "list-claims.sh is not present beside this skill"

out=$( ( cd "$ROOT" && sh "$lister" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded claims_unreadable "list-claims.sh produced no output"
printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded claims_unparseable "list-claims.sh produced output this step could not parse"

fetched=$(printf '%s' "$out" | jq -r '.fetched // false')
shallow=$(printf '%s' "$out" | jq -r '.shallow // false')

# Unmerged remote branches are the ONLY claim oracle, and the mergeability reading is derived
# against `origin/main`. A scan that could not reach the remote has not found "nothing blocked"
# — it has found nothing at all.
[ "$fetched" = "true" ] || emit degraded origin_unreachable \
    "the claim scan could not reach the remote; what no longer merges could not be read this tick"
[ "$shallow" = "true" ] && emit degraded shallow_history \
    "the claim scan ran over truncated history, so no merge base is visible and mergeability is unanswerable"

total=$(printf '%s' "$out" | jq '[.claims[]?] | length')

# A RACED UNIT IS ANOTHER STEP'S QUESTION (2026-08-30, mission
# `stop-two-runs-from-claiming-and-driving-one-unit`). Catching one of two racing branches up
# onto the base is not the act a person needs, because WHICH branch to keep is exactly what has
# not been decided; asking them to resolve a conflict on one of them presumes the answer.
# `raced-units` asks it; this step filters and COUNTS, the division this step is already one
# half of. The set is the library's own `claims_unit_resolution` over the scan already made, and
# an unreadable payload yields an empty set and filters nothing.
raced_set=$(raced_units "$out" 2>/dev/null || true)
raced_json='[]'
[ -z "$raced_set" ] || raced_json=$(printf '%s\n' "$raced_set" | jq -Rsc 'split("\n") | map(select(length > 0))')

candidates=$(printf '%s' "$out" | jq -c --argjson r "$raced_json" '
    [.claims[]? | select(.mergeability == "content")
                | select(.resume_reason == "report_undelivered" or .resume_reason == "queue_drained")
                | select(.unit as $u | ($r | index($u)) | not)]')
raced=$(printf '%s' "$out" | jq --argjson r "$raced_json" '
    [.claims[]? | select(.mergeability == "content")
                | select(.resume_reason == "report_undelivered" or .resume_reason == "queue_drained")
                | select(.unit as $u | $r | index($u))] | length')
n=$(printf '%s' "$candidates" | jq 'length')

summary="${total} claimed unit(s); ${n} finished and no longer merging"
[ "$raced" -eq 0 ] || summary="${summary}; ${raced} held by two live claims (asked by raced-units)"
[ "$n" -eq 0 ] && emit ok "" "$summary"

# The pull request's coordinates, one lookup per candidate and no more — the question has to
# name what a person is being asked to open. `claim-merged.sh` is three-valued: an
# `unanswerable` read leaves the coordinates unstated and KEEPS the candidate, because the
# finding is that the branch no longer merges, which the reading already established offline.
reader="${DRIVE_SCRIPTS}/claim-merged.sh"
rows=""
rsep=""
for branch in $(printf '%s' "$candidates" | jq -r '.[].branch'); do
    pr_url=""
    if [ -f "$reader" ]; then
        look=$( ( cd "$ROOT" && sh "$reader" "$branch" ) 2>/dev/null || true )
        pr_url=$(printf '%s' "$look" | jq -r '.pr_url // ""' 2>/dev/null || printf '')
    fi
    row=$(printf '%s' "$candidates" | jq -c --arg b "$branch" --arg u "$pr_url" '
        .[] | select(.branch == $b)
        | {unit, branch, owner: (.author // "unknown"),
           conflicted_files: (.mergeability_content_files // []),
           pull_request: (if $u == "" then "unknown" else $u end),
           key: ("catchup-blocked:" + .unit)}' 2>/dev/null || printf '')
    [ -n "$row" ] || continue
    rows="${rows}${rsep}${row}"
    rsep=","
done
rows="[${rows}]"

needs=$(printf '%s' "$rows" | jq -c '{action: "ask_the_claim_holder_to_resolve_the_conflict_the_loop_must_not_resolve",
    bound: "one question per unit, addressed to the claim holder, keyed on `key` so it is asked once; the tick asks and never merges, rebases, closes or touches a claim",
    compose: "name the branch, its pull request and the files both sides changed, and say the loop already tried to bring the branch back onto the base and stopped because only a person can judge this collision",
    blocked: .}' 2>/dev/null || echo '{}')

if [ "$n" -eq 1 ]; then
    event="a finished unit no longer merges with the base — the loop caught up as far as it may and stopped at a conflict only a person can judge"
else
    event="${n} finished units no longer merge with the base — the loop caught up as far as it may and stopped at conflicts only a person can judge"
fi

emit ok "" "$summary" "$needs" "$event"
