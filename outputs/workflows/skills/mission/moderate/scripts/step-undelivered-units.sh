#!/bin/sh -eu
# Step 18 — what the loop finished and could not deliver.
#
# WHY THIS STEP EXISTS (2026-08-27, mission `close-the-units-the-loop-already-finished`).
# `/implement` may not ask anyone anything, so an undelivered unit's story ends in a run report
# nobody opens. This tick is the one surface that reaches a person BY NAME, and none of its
# steps saw this shape: `step-stuck-prs.sh` and `step-merge-conflicts.sh` read pull requests and
# find one that is open and green, `step-stalled-units.sh` reads the claim oracle's STALE rows
# and this claim is not stale — its heartbeat advanced right up to the moment it finished.
# Measured 2026-08-27: four pull requests (#622, #625, #633, #635) green and unmerged, offered by
# no survey, told to nobody, with `ok` reported over all of them.
#
# WHICH SIBLING IT FOLLOWS, ON EACH AXIS (the ticket required this stated):
#
#   whose question           `stalled-units`'. The claim HOLDER is a real person who drove this
#                            unit and can retry its merge; unlike `undrivable-units`, whose
#                            finding is about the repository and whose owner is the direction's.
#   running identity         `undrivable-units`'. Never consulted. The claim's own `author` is
#                            the addressee, so the question is the same whichever container asks
#                            it — an hourly question that depended on who was asking would
#                            answer differently per account.
#   what it may read         `undrivable-units`'. `list-claims.sh` is a pure read; `plan-units.sh`
#                            is REFUSED, because the survey reaches the mission readers, which
#                            carry the living migrations and STAGE what they converge. A step
#                            whose contract is *writes nothing* may not reach it through
#                            something that writes — the reason `closable-missions` records.
#
# THE CANDIDATE SET IS THE SPLIT REASON, NOT A RE-DERIVATION. `report_undelivered` is the claim
# oracle's own verdict, and the refusal that produced it rides on the row as `merge_outcome`,
# read off the branch story the run recorded it in. Two readers of one script is not two sources
# of truth; a second opinion about whether a pull request is held by a gate or by a transport is
# exactly the disagreement that would reintroduce the silence.
#
# THE PULL REQUEST'S COORDINATES COST ONE LOOKUP PER CANDIDATE, and only per candidate. The
# question has to name the pull request a person is being asked to look at, and the claim row
# carries a branch rather than a URL. `claim-merged.sh` is the claim protocol's one network read
# and is three-valued: an `unanswerable` lookup does NOT drop the candidate — the finding is
# real whether or not we could name its URL — it just leaves the coordinates unstated, which is
# the honest rendering of a read we could not make.
#
# TWO AGES RIDE THIS QUESTION, AND THEY ARE TWO FACTS (2026-08-30, mission
# `say-how-long-the-loop-has-been-stuck`). `open_hours` is how long the PULL REQUEST has been
# open, from its own coordinates; `age` is how long the unit has been ASKED ABOUT, from the
# question ledger (`condition-age.sh`). This is the one step where both are present, and
# neither may silently replace the other: a pull request opened an hour ago that nobody has
# ever been told about, and one open for a week that a person was asked about on day one, are
# different situations calling for different acts. `drive/reference/claims.md`'s source table
# records which question reads which, and the rule it exists for — NOTHING DERIVES AN AGE
# TWICE, and where a question carries two they are named as two facts with their sources,
# never blended into one number.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, for the correctness reason
# `step-stalled-units.sh`'s header records: the moderation root calls a step changed when its
# summary differs from the same step's an hour ago, and `render-tick-post.sh` normalises out a
# timestamp, a bare hex object name and a clock time — and ONLY those. `open 14h` increments
# every tick, so it would make this step changed HOURLY by construction and the root would
# restate the same units all day, which is the shape `📦 Release Preparation` was retired for.
# The age still reaches the person, in the question that names the unit.
#
# Usage: step-undelivered-units.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
. "${SCRIPT_DIR}/lib/read-age.sh"
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts/"
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

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it.
# Empty means nothing happened here, and the renderer then emits no line at all.
emit() {
    printf '{"step": "undelivered-units", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
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

# Unmerged remote branches are the ONLY claim oracle, so a scan that could not reach the remote
# has not found "nothing undelivered" — it has found nothing at all. Reported by name rather
# than as a step that ran and found nothing.
[ "$fetched" = "true" ] || emit degraded origin_unreachable \
    "the claim scan could not reach the remote; what is undelivered could not be read this tick"
[ "$shallow" = "true" ] && emit degraded shallow_history \
    "the claim scan ran over truncated history; an undelivered unit is indistinguishable from a merged one"

total=$(printf '%s' "$out" | jq '[.claims[]?] | length')
# ONE UNIT NEVER DRAWS TWO QUESTIONS (2026-08-29, mission
# `land-the-loop-s-own-work-when-the-base-moves-under-it`). A unit whose branch the base no
# longer accepts reads `mergeability: content`, and `catchup-blocked` asks its holder to
# resolve that conflict. *Retry your merge* is the wrong instruction for such a branch — the
# transport is not what stopped it — so this step FILTERS the reading out of its own candidates
# and COUNTS it instead. One step asks and the other counts, exactly as `stalled-units` and
# `handoff-units` divide; either half alone is a defect, and the count keeps the finding
# visible in the log rather than dropping it.
# AND A RACED UNIT IS ANOTHER STEP'S QUESTION TOO (2026-08-30, mission
# `stop-two-runs-from-claiming-and-driving-one-unit`). When a unit is held by two live claims, a
# refused merge on one of them is the race's CONSEQUENCE, and *retry your merge* asks about the
# consequence while hiding the cause: what has not been decided is which of the two branches
# keeps going. `raced-units` asks that; this step filters and COUNTS, the same division the
# `content` reading above already follows. The set is the library's own `claims_unit_resolution`
# over the scan this step already made — no second walk, no second definition of a race — and an
# unreadable payload yields an empty set and filters nothing.
raced_set=$(raced_units "$out" 2>/dev/null || true)
raced_json='[]'
[ -z "$raced_set" ] || raced_json=$(printf '%s\n' "$raced_set" | jq -Rsc 'split("\n") | map(select(length > 0))')

candidates=$(printf '%s' "$out" \
    | jq -c --argjson r "$raced_json" '[.claims[]? | select(.resume_reason == "report_undelivered")
                        | select(.mergeability != "content")
                        | select(.unit as $u | ($r | index($u)) | not)]')
blocked=$(printf '%s' "$out" \
    | jq '[.claims[]? | select(.resume_reason == "report_undelivered")
                     | select(.mergeability == "content")] | length')
raced=$(printf '%s' "$out" \
    | jq --argjson r "$raced_json" '[.claims[]? | select(.resume_reason == "report_undelivered")
                     | select(.mergeability != "content")
                     | select(.unit as $u | $r | index($u))] | length')
n=$(printf '%s' "$candidates" | jq 'length')

summary="${total} claimed unit(s); ${n} finished and undelivered"
[ "$blocked" -eq 0 ] || summary="${summary}; ${blocked} no longer merging (asked by catchup-blocked)"
[ "$raced" -eq 0 ] || summary="${summary}; ${raced} held by two live claims (asked by raced-units)"

if [ "$n" -eq 0 ]; then
    emit ok "" "$summary"
fi

# THE COORDINATES, one lookup per candidate and no more. An `unanswerable` read leaves the
# fields unstated and keeps the candidate: the finding is that the unit is undelivered, which
# the claim oracle already established offline.
reader="${DRIVE_SCRIPTS}/claim-merged.sh"
rows=""
rsep=""
for branch in $(printf '%s' "$candidates" | jq -r '.[].branch'); do
    pr_url=""
    open_hours=null
    if [ -f "$reader" ]; then
        look=$( ( cd "$ROOT" && sh "$reader" "$branch" ) 2>/dev/null || true )
        pr_url=$(printf '%s' "$look" | jq -r '.pr_url // ""' 2>/dev/null || printf '')
        open_hours=$(printf '%s' "$look" | jq -r '.open_hours // "null"' 2>/dev/null || printf 'null')
        case "$open_hours" in ''|*[!0-9]*) open_hours=null ;; esac
    fi
    unit=$(printf '%s' "$candidates" | jq -r --arg b "$branch" '.[] | select(.branch == $b) | .unit' 2>/dev/null || printf '')
    age=$(read_age "undelivered-unit:${unit}")
    row=$(printf '%s' "$candidates" | jq -c --arg b "$branch" --arg u "$pr_url" \
        --argjson h "$open_hours" --argjson age "$age" '
            .[] | select(.branch == $b)
            | {unit, branch, owner: (.author // "unknown"),
               refusal: (if (.merge_outcome // "") == "" then "unrecorded" else .merge_outcome end),
               pull_request: (if $u == "" then "unknown" else $u end),
               open_hours: $h,
               age: $age,
               key: ("undelivered-unit:" + .unit)}' 2>/dev/null || printf '')
    [ -n "$row" ] || continue
    rows="${rows}${rsep}${row}"
    rsep=","
done
rows="[${rows}]"

# THE QUESTION IS HELD ONCE THIS FINDING HAS BECOME WORK (2026-08-29, mission
# `let-the-tick-s-own-findings-become-the-loop-s-work`). While an open finding issue carries
# this step's finding, the loop is already driving the repair, so asking a person about it asks
# them — the same person, in the same hour — about the thing in flight. Keyed on the SUBJECT,
# so a filing about another step's finding silences nothing here; an unreadable read holds
# nothing (`ci-retirement-turn.sh`'s discipline); and the suppression is derived, so merging or
# closing the issue makes the question reachable again with no state anywhere. `ask-question.sh`,
# the key, the addressee, the caps and the holds are untouched — only the questions are withheld,
# and the summary still counts what the step found.
finding_held=false
suppression="${SCRIPT_DIR}/finding-suppression.sh"
if [ -f "$suppression" ]; then
    fsupp=$( ( cd "$ROOT" && sh "$suppression" ) 2>/dev/null || true )
    if [ -n "$fsupp" ] && printf '%s' "$fsupp" | jq -e '.readable // false' >/dev/null 2>&1; then
        if printf '%s' "$fsupp" | jq -e '.held.steps | index("undelivered-units")' >/dev/null 2>&1; then
            finding_held=true
        fi
    fi
fi
if [ "$finding_held" = "true" ]; then
    emit ok finding_filed \
        "${summary} — held: an open finding issue already carries this" "" ""
fi

needs=$(printf '%s' "$rows" | jq -c '{action: "ask_the_claim_holder_to_retry_the_merge_on_this_finished_unit",
    bound: "one question per unit, addressed to the claim holder, keyed on `key` so it is asked once; the tick asks and never merges, drives or retries anything itself",
    compose: "name the unit, its pull request and the refusal that stopped the merge, and say the unit is finished and green -- what is needed is the merge, not a review. Two ages may be present and they are TWO FACTS: `open_hours` is how long the PULL REQUEST has been open, `age` is how long the unit has been ASKED ABOUT (`age.ticks` ticks since `age.first_seen`, `at least` that when `age.first_seen_is_floor`). Never present one as the other, and omit the second when it adds nothing. Say nothing about the log age when `age.first_seen` is null and the reading is readable -- that is the first time anybody is being asked. When `age.readable` is false, name it as an age we could not read, by its `age.reason`, never as a condition that just started.",
    undelivered: .}' 2>/dev/null || echo '{}')

if [ "$n" -eq 1 ]; then
    event="a finished unit was never delivered — its pull request is open and its merge was refused"
else
    event="${n} finished units were never delivered — their pull requests are open and their merges were refused"
fi

emit ok "" "$summary" "$needs" "$event"
