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
# IT ANSWERS ONE QUESTION AND IT IS NOT `IS THERE A NEW UNIT TO CLAIM` (2026-09-06, mission
# `finish-the-backlog-without-handing-it-back-to-the-operator`). The question a fan-out depends on
# is *is there work an `/implement` pass would act on*, and those two stopped being the same
# question once the Unified Run grew its recovery and delivery acts. Measured, and reproducible by
# feeding this reader a survey whose only work is one `report_undelivered` unit: it answered
# `claimable: 0`, byte-identical to a repository with genuinely nothing to do, so the tick spawned
# no runner at all — while an `/implement` pass would have caught the branch up and merged it. The
# operator's own report of the failure is 28 tickets waiting, zero units and four conflicting pull
# requests with no pass ever run to inspect them. So the count now includes the recovery and
# delivery work the Unified Run already acts on, composed from readers that already exist:
# `plan-units.sh`'s own `undelivered[]`, `drive/scripts/list-catchable-claims.sh` and
# `branching/scripts/list-stranded-publications.sh`. No second walker, no new field on any
# artifact, and no verdict re-derived here.
#
# ALL RECOVERY WORK IS ONE UNIT, FOR THE REASON LOOSE BACKLOG IS. Those three acts are
# **once-per-run** readings inside the Unified Run: a single `/implement` pass walks every
# undelivered entry, every catchable claim and every stranded publication it finds. Counting them
# per entry would spawn N runners to do one runner's work, and they would race each other on the
# same pull requests. So the recovery term contributes AT MOST ONE unit, and the per-term counts
# ride beside it (`undelivered`, `catchable`, `stranded`) so the tick's allocation line can name
# which term earned the runner rather than reporting a bare number.
#
# THE COUNT IS DELIBERATELY CONSERVATIVE ON LOOSE BACKLOG. A mission is one unit by construction,
# but loose tickets are partitioned into batch units at §2 of the Unified Run, by a judgement this
# reader does not make and must not pre-empt. All loose backlog is therefore counted as ONE unit:
# under-counting spawns fewer runners than the queue could carry, over-counting spawns runners
# that find nothing and spend a whole agent run losing a claim race.
#
# A UNIT IN TWO RECOVERY SETS IS COUNTED ONCE. A `report_undelivered` claim whose branch is behind
# the base appears in both `undelivered[]` and the catchable candidates, and the Unified Run takes
# it once (the `undelivered[]` loop catches it up before its retry). The union is taken on the unit
# id, so the terms below can be added without double-counting the same branch.
#
# A MANDATORY TAKEOVER IS CLAIMABLE WORK. `heartbeat_lapsed` and `report_incomplete` are the two
# resume reasons the token table calls `pending` when a run leaves them untaken, so they are work
# a runner can be spawned for. `parked_with_pr`, `awaiting_verification` and `superseded` still are
# not counted AS UNITS TO CLAIM, and the widening above does not reach them — but the reason is
# worth restating per verdict, because two of the three have moved. `superseded` holds nothing to
# drive and its retirement is CI's, so it earns no runner. `parked_with_pr` waits on a person by
# the oracle's own word; where its branch has fallen behind it is already counted through the
# catchable term, which is the actionable half of it. `awaiting_verification` waits on a DECLARED
# verification — and since 2026-09-03 a declaration may be a probe re-run at claim time, so a
# stale one is falsified where the unit is claimed rather than here: this reader does not run
# probes, and counting the verdict on the chance that its probe now reads `clean` would spawn a
# runner on a guess. SINCE 2026-09-07 IT TOO IS REACHED THROUGH THE CATCHABLE TERM (ticket
# `20260907070931-offer-an-awaiting-verification-claim-to-the-catch-up`), on exactly
# `parked_with_pr`'s footing: `list-catchable-claims.sh` offers such a claim whose branch has
# fallen behind, so a handoff branch needing a catch-up IS work an `/implement` pass would act on
# and the count rises. Nothing here filters by verdict — this reader composes that one — and the
# unit is still not counted as a takeover, because the catch-up delivers nothing for it.
#
# A SURVEY THAT COULD NOT BE MADE YIELDS NO READING. The five facts `plan-units.sh` forbids `ok`
# on — `current: false`, `shallow: true`, a non-empty `backlog_error`, `owner_unresolved`, and
# `placeholder_identity` — each answer `readable: false` with that word and a NULL count, never a
# zero. A gate that cannot be read is not a gate, and an allocation decided on a blind survey is
# worse than the fixed one it replaced. A RECOVERY COMPONENT THAT COULD NOT BE READ ANSWERS THE
# SAME WAY (`catchable_unreadable`, `stranded_unreadable`): a zero there is the exact collapse
# this change exists to close, and the caller's stated behaviour on `readable: false` is to fall
# back to one runner and report it — so an unreadable component still spawns the pass, which a
# zero would not.
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
# once; the tick has not, so the cost is real for it. The two recovery readers add REST reads of
# this repository's open pull requests — bounded listings both, and each is made once per tick
# rather than once per entry. `--recovery <path|->` is the same escape hatch for a caller that has
# already made those readings, taking the union pre-computed as `{"units": [...], "stranded": n}`;
# a caller that has not simply pays.
#
# Usage: claimable-units.sh [--survey <path|->] [--recovery <path|->]
# Output: one JSON line
#   {"claimable": n, "missions": n, "backlog_units": n, "resumable": n,
#    "recovery_units": n, "undelivered": n, "catchable": n, "stranded": n}
#   {"claimable": null, "missions": null, "backlog_units": null, "resumable": null,
#    "recovery_units": null, "undelivered": null, "catchable": null, "stranded": null,
#    "readable": false, "reason": "<word>"}
#
# PURE READ. No file, no commit, no branch, no post. The two recovery readers make bounded REST
# reads of this repository's own pull requests; nothing is written anywhere.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PLAN="${SCRIPT_DIR}/../../drive/scripts/plan-units.sh"
CATCHABLE="${SCRIPT_DIR}/../../drive/scripts/list-catchable-claims.sh"
STRANDED="${SCRIPT_DIR}/../../branching/scripts/list-stranded-publications.sh"

SURVEY=""
RECOVERY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --survey) SURVEY="${2:-}"; shift 2 ;;
        --recovery) RECOVERY="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done

emit_unreadable() {
    printf '{"claimable": null, "missions": null, "backlog_units": null, "resumable": null, "recovery_units": null, "undelivered": null, "catchable": null, "stranded": null, "readable": false, "reason": "%s"}\n' "$1"
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

# --- The recovery term -------------------------------------------------------------------
# The union of the unit ids the Unified Run's recovery acts would take, plus the count of the
# stranded publications it would settle. Pre-computed by the caller with `--recovery`, else read
# here from the two readers that already answer these questions.

if [ -n "$RECOVERY" ]; then
    if [ "$RECOVERY" = "-" ]; then
        rec=$(cat)
    else
        [ -f "$RECOVERY" ] || emit_unreadable recovery_unreadable
        rec=$(cat "$RECOVERY")
    fi
    printf '%s' "$rec" | jq -e . >/dev/null 2>&1 || emit_unreadable recovery_unreadable
    catch_units=$(printf '%s' "$rec" | jq -r '(.units // [])[]' 2>/dev/null) || emit_unreadable recovery_unreadable
    stranded_count=$(printf '%s' "$rec" | jq -r '.stranded // 0' 2>/dev/null) || emit_unreadable recovery_unreadable
else
    [ -f "$CATCHABLE" ] || emit_unreadable catchable_unreadable
    catch_out=$(sh "$CATCHABLE" 2>/dev/null) || emit_unreadable catchable_unreadable
    printf '%s' "$catch_out" | jq -e '.ok == true' >/dev/null 2>&1 || emit_unreadable catchable_unreadable
    catch_units=$(printf '%s' "$catch_out" | jq -r '(.candidates // [])[] | .unit' 2>/dev/null) \
        || emit_unreadable catchable_unreadable

    [ -f "$STRANDED" ] || emit_unreadable stranded_unreadable
    stranded_out=$(sh "$STRANDED" 2>/dev/null) || emit_unreadable stranded_unreadable
    printf '%s' "$stranded_out" | jq -e '.ok == true' >/dev/null 2>&1 || emit_unreadable stranded_unreadable
    # Only the classes `settle-stranded-publication.sh` acts on. `unanswerable` is the absence of a
    # reading and is never actionable, so it earns no runner.
    stranded_count=$(printf '%s' "$stranded_out" \
        | jq -r '[(.publications // [])[] | select(.mergeability == "mechanical" or .mergeability == "clean" or .mergeability == "content")] | length' 2>/dev/null) \
        || emit_unreadable stranded_unreadable
fi

case "$stranded_count" in
    ''|*[!0-9]*) emit_unreadable stranded_unreadable ;;
esac

undelivered_units=$(printf '%s' "$raw" | jq -r '(.undelivered // [])[] | .unit' 2>/dev/null) \
    || emit_unreadable survey_unreadable

undelivered_count=$(printf '%s\n' "$undelivered_units" | grep -c . || true)
catchable_count=$(printf '%s\n' "$catch_units" | grep -c . || true)
union_count=$(printf '%s\n%s\n' "$undelivered_units" "$catch_units" | grep . | sort -u | wc -l | tr -d ' ')
[ -n "$union_count" ] || union_count=0

recovery_units=0
if [ "$union_count" -gt 0 ] || [ "$stranded_count" -gt 0 ]; then
    recovery_units=1
fi

printf '%s' "$raw" | jq -c \
    --argjson recovery "$recovery_units" \
    --argjson undelivered "$undelivered_count" \
    --argjson catchable "$catchable_count" \
    --argjson stranded "$stranded_count" '
    (.missions | length) as $m
    | (if ((.backlog | length) > 0) then 1 else 0 end) as $b
    | ([.resumable[]? | select(.resume_reason == "heartbeat_lapsed" or .resume_reason == "report_incomplete")] | length) as $r
    | {claimable: ($m + $b + $r + $recovery), missions: $m, backlog_units: $b, resumable: $r,
       recovery_units: $recovery, undelivered: $undelivered, catchable: $catchable, stranded: $stranded}' 2>/dev/null \
    || emit_unreadable survey_unreadable
