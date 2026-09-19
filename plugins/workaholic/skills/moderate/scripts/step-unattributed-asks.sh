#!/bin/sh -eu
# Step 35 — an open operator ask that answers no active direction.
#
# WHY THIS STEP EXISTS (2026-09-19, ticket `20260919093809`, operator's ask issue #907 item 3:
# *a move is declared against a strategy, so an ask with no direction can never be originated;
# `unattributed` exists on the inbound path and has no counterpart here*). MEASURED: the
# operator's own stated immediate priority belonged to no active strategy, so `/propose` was
# structurally incapable of proposing it and spent two days proposing against the directions
# that did exist.
#
# WHY A SIBLING STEP RATHER THAN A WIDENING OF `direction-health`. That step's subject is a
# DIRECTION — its verdict, its maturity, its assignee — and an ask that answers no direction has
# none of those, so it has no honest row there. `unanswered-asks` is not the home either: its
# subject is a message on the channel. Two subjects in one step is how two readings start to
# disagree, the rule this repository already records for `overdue` versus `pace`.
#
# WHAT IT READS, AND NOTHING ELSE. `strategy/scripts/unattributed-asks.sh` — the mirror of
# `unattributed-work.sh`, composing `list-inbound-issues.sh` and the strategy readers. This step
# adds no walk, no relation and no field; it renders that one reading and asks about it.
#
# `undecidable_here` IS RENDERED AS WHAT IT MEANS. The reader answers only the two mechanical
# attribution rungs — an explicit `feedback:` line, an explicit slug — because the third is a
# judgement against the Aims that `/specificate` step 7 owns and no script may assert. So the
# question says *no line and no slug name a direction for this ask*, never *this ask belongs to
# no direction*.
#
# IT CREATES AND AMENDS NOTHING. `strategy/scripts/create.sh` and `amend.sh` keep their three
# writers; this step opens no proposal, files no ticket, closes nothing and touches no claim.
# `rules/workaholic.md`, *What May Originate a Mission*, is unchanged: the loop names the ask,
# and giving it a direction is the operator's act.
#
# ONE QUESTION PER ASK, keyed `unattributed-ask:<number>` through the existing asked-once gate,
# with `condition-age.sh` answering how long that question has been standing. The age is the
# QUESTION's, a lower bound on the ask's own, so the body says *asked about since* and never
# asserts how long the ask has been uncovered.
#
# THE SUMMARY CARRIES A COUNT AND THE NUMBERS, AND NO CLOCK-DERIVED VALUE. The root calls a step
# changed when its summary differs from the same step's an hour ago; an unchanged set has an
# unchanged count and unchanged numbers, so an unchanged condition renders no new root line. Two
# keyed roots have already been retired here for exactly that.
#
# Usage: step-unattributed-asks.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
READER="${SCRIPT_DIR}/../../strategy/scripts/unattributed-asks.sh"
AGE="${SCRIPT_DIR}/condition-age.sh"

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

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

emit() {
    printf '{"step": "unattributed-asks", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

[ -f "$READER" ] || emit degraded no_reader "unattributed-asks.sh is not present in this checkout"

out=$(sh "$READER" --root "${ROOT}/.workaholic" 2>/dev/null || true)
if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    emit degraded reader_unreadable "the unattributed-ask reading returned nothing this step could parse"
fi

# `readable` is absent on a completed walk, so the test is `readable == false` and never
# `readable // true`: a degraded read is named by its own reason, never rendered as an empty set.
if printf '%s' "$out" | jq -e '.readable == false' >/dev/null 2>&1; then
    why=$(printf '%s' "$out" | jq -r '.reason // "unreadable"' 2>/dev/null || printf unreadable)
    emit degraded "$why" "the open asks could not be judged against the active directions: ${why}"
fi

count=$(printf '%s' "$out" | jq -r '.ask_count // 0' 2>/dev/null || printf 0)
case "$count" in ''|*[!0-9]*) emit degraded reader_unreadable "the unattributed-ask reading carried no count" ;; esac
[ "$count" -gt 0 ] || emit ok "" "every open ask this identity holds is covered by an active direction"

numbers=$(printf '%s' "$out" | jq -r '[.asks[].number | tostring] | join(", ")' 2>/dev/null || printf '')

# One question per ask. `condition-age.sh` answers how long the QUESTION has stood; a subject
# nobody has been asked about yet reads `first_seen: null`, the ordinary first time.
needs=''
for number in $(printf '%s' "$out" | jq -r '.asks[].number' 2>/dev/null || true); do
    key="unattributed-ask:${number}"
    age='{"first_seen": null, "ticks": null}'
    if [ -f "$AGE" ]; then
        got=$(sh "$AGE" --key "$key" --root "$ROOT" 2>/dev/null || true)
        printf '%s' "$got" | jq -e . >/dev/null 2>&1 && age="$got"
    fi
    row=$(printf '%s' "$out" | jq -c --arg n "$number" --argjson age "$age" '
        .asks[] | select((.number | tostring) == $n)
        | {action: "ask_whether_this_ask_wants_a_direction",
           bound: "one question, keyed on `key`. The step asks and nothing else — it creates no strategy, amends none, opens no proposal and files no ticket. `rules/workaholic.md`, *What May Originate a Mission*, is unchanged: only a human'"'"'s ask or a human-authored strategy may originate, and giving this ask a direction is the operator'"'"'s act.",
           compose: "say that this open ask names no active direction — NO `feedback:` LINE AND NO SLUG, which is what `undecidable_here` means, never *it belongs to no direction* — and ask whether it wants one. Name the issue number, its title and its link. The age is the QUESTION'"'"'s, a lower bound on the ask'"'"'s own, so say *asked about since* and never assert how long the ask has been uncovered.",
           number: .number, title: .title, url: .url, ask_reason: .reason,
           age: $age, key: $key}' --arg key "$key" 2>/dev/null || printf '')
    [ -n "$row" ] || continue
    needs="${needs:+${needs}, }${row}"
done

emit blocked uncovered_asks \
    "$(json_escape "${count} open ask(s) name no active direction (no feedback line, no slug): ${numbers}")" \
    "$needs" \
    "$(json_escape "${count} open ask(s) answer no active direction: ${numbers}")"
