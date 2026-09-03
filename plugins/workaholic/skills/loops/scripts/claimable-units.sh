#!/bin/sh -eu
# How much independently claimable work this tick has, so an allocation can depend on it.
#
# WHY IT EXISTS (2026-09-03, mission `decide-each-tick-s-allocation-from-what-the-tick-just-read`).
# The tick's allocation was a constant and the loop's state was not, so the bottleneck never got
# capacity and a runner with nothing to do was walked anyway. Measured over two hours: 54 tickets
# across 8 active missions and, by the concurrency rule, exactly ONE `implement` runner — about
# seven hours of serial queue.
#
# IT COMPOSES THE SURVEY AND DERIVES NOTHING OF ITS OWN. `drive/scripts/plan-units.sh` is the
# executor's own partition: it groups missions into units, resolves ownership through the one
# oracle, subtracts everything a claim holds, and names every exclusion. Counting `todo/` files
# instead would ignore missions, claims, ownership and every exclusion reason the survey already
# derives — and would hand the tick a number the executor would then refuse.
#
# THE COUNT IS DELIBERATELY CONSERVATIVE ON LOOSE BACKLOG. A mission is one unit by construction,
# but loose tickets are partitioned into batch units at §2 of the Unified Run, by a judgement this
# reader does not make and must not pre-empt. All loose backlog is therefore counted as ONE unit:
# under-counting spawns fewer runners than the queue could carry, over-counting spawns runners
# that find nothing and spend a whole agent run losing a claim race.
#
# A MANDATORY TAKEOVER IS CLAIMABLE WORK. `heartbeat_lapsed` and `report_incomplete` are the two
# resume reasons the token table calls `pending` when a run leaves them untaken, so they are work
# a runner can be spawned for. `parked_with_pr`, `awaiting_verification` and `superseded` are not:
# each waits on a person or holds nothing.
#
# A SURVEY THAT COULD NOT BE MADE YIELDS NO READING. The five facts `plan-units.sh` forbids `ok`
# on — `current: false`, `shallow: true`, a non-empty `backlog_error`, `owner_unresolved`, and
# `placeholder_identity` — each answer `readable: false` with that word and a NULL count, never a
# zero. A gate that cannot be read is not a gate, and an allocation decided on a blind survey is
# worse than the fixed one it replaced.
#
# `readable` IS ABSENT ON A COMPLETED READ, the `merge_policy` / `status:` convention this
# repository already holds: absent means it completed, so a consumer tests `readable == false` and
# never `readable // true`.
#
# COST, MEASURED AND STATED RATHER THAN WORKED AROUND (2026-09-03, on the machine the loop runs
# on, 4 cores): `plan-units.sh` takes **68-73 seconds**, three consecutive runs, warm. That is
# roughly a quarter of a five-minute tick, and it is reported as a finding rather than routed
# around with a lighter count — a cheaper number that the executor would then refuse is not a
# saving. `--survey <path|->` exists so a caller that has ALREADY made the survey pays for it
# once; the tick has not, so the cost is real for it.
#
# Usage: claimable-units.sh [--survey <path|->]
# Output: one JSON line
#   {"claimable": n, "missions": n, "backlog_units": n, "resumable": n}
#   {"claimable": null, "missions": null, "backlog_units": null, "resumable": null,
#    "readable": false, "reason": "<word>"}
#
# PURE READ. No file, no commit, no branch, no network of its own, no post.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PLAN="${SCRIPT_DIR}/../../drive/scripts/plan-units.sh"

SURVEY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --survey) SURVEY="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done

emit_unreadable() {
    printf '{"claimable": null, "missions": null, "backlog_units": null, "resumable": null, "readable": false, "reason": "%s"}\n' "$1"
    exit 0
}

if [ -n "$SURVEY" ]; then
    if [ "$SURVEY" = "-" ]; then
        raw=$(cat)
    else
        [ -f "$SURVEY" ] || emit_unreadable survey_unreadable
        raw=$(cat "$SURVEY")
    fi
else
    [ -f "$PLAN" ] || emit_unreadable survey_unreadable
    raw=$(sh "$PLAN" 2>/dev/null) || emit_unreadable survey_unreadable
fi

[ -n "$raw" ] || emit_unreadable survey_unreadable

# The five `ok`-forbidding facts, in the order `plan-units.sh` documents them. The FIRST that
# holds is the reason, so a survey failing two ways names one word rather than a compound.
reason=$(printf '%s' "$raw" | jq -r '
    if (.current // false) != true then "not_current"
    elif (.shallow // false) == true then "shallow"
    elif ((.backlog_error // "") | length) > 0 then "backlog_error"
    elif (.owner_unresolved // false) == true then "owner_unresolved"
    elif (.placeholder_identity // false) == true then "placeholder_identity"
    else "" end' 2>/dev/null) || emit_unreadable survey_unreadable

case "$reason" in
    '') : ;;
    null) emit_unreadable survey_unreadable ;;
    *) emit_unreadable "$reason" ;;
esac

printf '%s' "$raw" | jq -c '
    (.missions | length) as $m
    | (if ((.backlog | length) > 0) then 1 else 0 end) as $b
    | ([.resumable[]? | select(.resume_reason == "heartbeat_lapsed" or .resume_reason == "report_incomplete")] | length) as $r
    | {claimable: ($m + $b + $r), missions: $m, backlog_units: $b, resumable: $r}' 2>/dev/null \
    || emit_unreadable survey_unreadable
