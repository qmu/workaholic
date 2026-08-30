#!/bin/sh -eu
# Step — the pull requests the loop opened FOR A PERSON and that nobody has acted on.
#
# WHY THIS STEP EXISTS (2026-08-29, mission `follow-the-pull-requests-the-loop-opens-for-a-person`).
# `publish-tree-pr.sh` refuses to auto-merge two kinds of publication — a ruling and a strategy
# — precisely because MERGING IS THE OPERATOR'S RULING AND CLOSING IS THEIR REFUSAL. Having
# opened the diff, the loop then stopped following it. Measured 2026-08-29: #694 sat 18 hours
# unanswered while `ruling-suppression.sh` held the `undrivable-unit:` questions for the very
# addresses it names, and `plan-units.sh` offered nothing over a backlog of 10 — 7 of them
# excluded `owned_by_other` on the one address #694 would map.
#
# No other step could see it. `stuck-prs` and `merge-conflicts` read the open pull requests and
# find this one perfectly healthy — it is not stuck, it is WAITING, which is what it was opened
# to do. Every claim-side verdict (`undelivered-units`, `handoff-units`, `catchup-blocked`,
# `stalled-units`) is bounded to a CLAIM, and a publication carries none: `publish-tree-pr.sh`
# pushes `publish-main` to a `work-*` name with no `Claim` commit in it, which is exactly what
# keeps a publication invisible to the claim protocol.
#
# WHICH SIBLING IT FOLLOWS, ON EACH AXIS:
#
#   whose question           the OPERATOR'S — `direction-health`'s addressee, resolved from the
#                            active directions' assignees, because the operator is the person
#                            this repository records as owning a direction and a ruling is
#                            theirs to settle. An unresolved address leaves the question
#                            addressed to NOBODY rather than stamping one nobody verified
#                            (`base-health`'s rule).
#   running identity         `undrivable-units`'. Never consulted. An unanswered publication is
#                            a fact about the repository, so an hourly question that depended on
#                            which container asked it would answer differently per account.
#   where it sits            after `thread-reconcile`, in the cluster of steps that read a pull
#                            request or a claim and hand it to a person. `handoff-units
#                            thread-reconcile` stays adjacent because that pair is pinned.
#   what it may read         `undrivable-units`'. `plan-units.sh` is REFUSED — that survey
#                            reaches the mission readers, which carry the living migrations and
#                            STAGE what they converge, and a step whose contract is *writes
#                            nothing* may not reach it through something that writes.
#
# MEMBERSHIP IS THE SEAM'S REFUSAL WORD, NEVER A TITLE. `list-operator-facing-pulls.sh` derives
# it from the shape of the change through the same `lib/publication-refusal.sh` the seam itself
# reads, so a pull request the operator retitled or opened by hand is still theirs, and an
# ordinary `[Proposal]` that auto-merged never appears. Measured on this repository the same
# day: of 7 open pull requests exactly one (#694) is the operator's, and the ask's own guess
# that #688 and #625 were strategy publications was WRONG — neither touches a strategy.
#
# AND WHAT MERGING IT WOULD UNBLOCK COMES FROM THE HOLD'S OWN READER, so the two cannot diverge
# (2026-08-29, the same mission's ruling-hold ticket). `ruling-suppression.sh` is the one script
# that knows which subjects an open ruling is holding; this step COMPOSES it rather than
# re-deriving the subject list, which is the rule that reader's header already states for its
# own two consumers. THIS QUESTION IS WHAT BREAKS THE SILENCE: the hold stays exactly as it is —
# keyed on the subject, releasing nothing on a timer — and the person who can end it is now
# told, once, that a pull request is waiting on them and what it holds. Releasing the hold AS
# WELL would ask one person twice, in two vocabularies, about one pull request, which is the
# doubling `handoff-units` and `stalled-units` were split to avoid.
#
# AN `unreadable` READING DRAWS NO QUESTION and is counted in the summary — `strategy-pace`'s
# rule that a person's attention is not spent on our own degradation.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, for the correctness reason
# `step-undelivered-units.sh`'s header records: the root calls a step changed when its summary
# differs from the same step's an hour ago, and `open 18h` increments every tick, so it would
# make this step changed HOURLY by construction. The age still reaches the person, in the
# question that names the pull request.
#
# IT ASKS AND NOTHING ELSE. No merge, no close, no comment, no gate, no hold of work, no lifted
# gate, and nothing written anywhere but its own log line (`run.sh` writes that).
#
# Usage: step-operator-pulls.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts"
STRATEGY_SCRIPTS="${SCRIPT_DIR}/../../strategy/scripts"
BRANCHING_SCRIPTS="${SCRIPT_DIR}/../../branching/scripts"

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
    printf '{"step": "operator-pulls", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

lister="${BRANCHING_SCRIPTS}/list-operator-facing-pulls.sh"
effect="${BRANCHING_SCRIPTS}/publication-effect.sh"
[ -f "$lister" ] || emit degraded no_pull_reader "list-operator-facing-pulls.sh is not present beside the branching skill"
[ -f "$effect" ] || emit degraded no_effect_reader "publication-effect.sh is not present beside the branching skill"

out=$( ( cd "$ROOT" && sh "$lister" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded pulls_unreadable "the operator-facing pull requests could not be read this tick"
printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded pulls_unparseable "the operator-facing pull request reader produced output this step could not parse"

# `ok: false` carries NO pull list at all, which is the whole point of that contract: *nothing
# waits on the operator* and *we could not look* are opposite facts.
[ "$(printf '%s' "$out" | jq -r '.ok // false')" = "true" ] \
    || emit degraded "$(printf '%s' "$out" | jq -r '.reason // "pulls_unreadable"')" \
        "the operator-facing pull requests could not be read; what waits on a person is unknown this tick"

candidates=$(printf '%s' "$out" | jq -c '.pulls // []')
n_candidates=$(printf '%s' "$candidates" | jq 'length')
truncated=$(printf '%s' "$out" | jq -r '.truncated // false')

if [ "$n_candidates" -eq 0 ]; then
    summary="no open pull request waits on the operator"
    [ "$truncated" = "true" ] && summary="${summary} (the open set was read to the cap)"
    emit ok "" "$summary"
fi

# WHAT THE RULING HOLDS, from the hold's own reader and not from a second derivation.
held_json='{"attribution": [], "identity_mapping": []}'
held_readable=false
suppression="${SCRIPT_DIR}/ruling-suppression.sh"
if [ -f "$suppression" ]; then
    rsupp=$( ( cd "$ROOT" && sh "$suppression" ) 2>/dev/null || true )
    if [ -n "$rsupp" ] && printf '%s' "$rsupp" | jq -e '.readable // false' >/dev/null 2>&1; then
        held_readable=true
        held_json=$(printf '%s' "$rsupp" | jq -c '.held')
    fi
fi

# THE ADDRESSEE: the operator, resolved from the active directions' assignees. This repository
# records no other "operator" field, and `validate-strategy.sh` floors a strategy's `assignees`
# non-empty precisely because that artifact is the one place a person is named as owning the
# direction. Several live directions with different owners give several addressees — a ruling is
# repository-wide and each of them has standing to settle it — and none resolving leaves the
# question addressed to nobody.
addressees=""
if [ -f "${STRATEGY_SCRIPTS}/list.sh" ]; then
    raw=$( ( cd "$ROOT" && sh "${STRATEGY_SCRIPTS}/list.sh" ) 2>/dev/null || true )
    if [ -n "$raw" ] && printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then
        for a in $(printf '%s' "$raw" \
            | jq -r '[.strategies[]? | select(.status == "active") | .assignees]
                     | map(select(. != null and . != "")) | join(",")' 2>/dev/null \
            | tr ',' ' '); do
            [ -n "$a" ] || continue
            canon="$a"
            if [ -f "${GATHER_SCRIPTS}/identity.sh" ]; then
                ident=$( sh "${GATHER_SCRIPTS}/identity.sh" "$a" 2>/dev/null || true )
                c=$(printf '%s' "$ident" | jq -r '.canonical // ""' 2>/dev/null || printf '')
                [ -z "$c" ] || canon="$c"
            fi
            case " $addressees " in
                *" $canon "*) : ;;
                *) addressees="${addressees:+$addressees }$canon" ;;
            esac
        done
    fi
fi

rows=""
rsep=""
open_n=0
settled_n=0
unreadable_n=0

for number in $(printf '%s' "$candidates" | jq -r '.[].number'); do
    eff=$( ( cd "$ROOT" && sh "$effect" "$number" ) 2>/dev/null || true )
    word=$(printf '%s' "$eff" | jq -r '.effect // "unreadable"' 2>/dev/null || printf 'unreadable')
    age=$(printf '%s' "$eff" | jq -r '.age_hours // "null"' 2>/dev/null || printf 'null')
    case "$age" in ''|*[!0-9]*) age=null ;; esac

    case "$word" in
        merged|closed) settled_n=$((settled_n + 1)); continue ;;
        unreadable)    unreadable_n=$((unreadable_n + 1)); continue ;;
    esac
    open_n=$((open_n + 1))

    row=$(printf '%s' "$candidates" | jq -c --argjson num "$number" \
        --arg who "$addressees" --argjson age "$age" \
        --argjson held "$held_json" --argjson hr "$held_readable" '
        .[] | select(.number == $num)
        | {number, url, title, refusal_word,
           addressees: (if $who == "" then [] else ($who | split(" ")) end),
           open_hours: $age,
           unblocks: (if $hr then
                        {missions: ($held.attribution // []), addresses: ($held.identity_mapping // [])}
                      else null end),
           key: ("operator-pull:" + (.number | tostring))}' 2>/dev/null || printf '')
    [ -n "$row" ] || continue
    rows="${rows}${rsep}${row}"
    rsep=","
done
rows="[${rows}]"

summary="${n_candidates} operator-facing pull request(s); ${open_n} un-acted"
[ "$settled_n" -eq 0 ] || summary="${summary}; ${settled_n} already merged or closed"
[ "$unreadable_n" -eq 0 ] || summary="${summary}; ${unreadable_n} unreadable (asked about by nobody)"
[ "$held_readable" = "true" ] || summary="${summary}; what they hold could not be read"
[ "$truncated" = "true" ] && summary="${summary}; the open set was read to the cap"

if [ "$open_n" -eq 0 ]; then
    emit ok "" "$summary"
fi

needs=$(printf '%s' "$rows" | jq -c '{action: "ask_the_operator_to_rule_on_this_pull_request",
    bound: "one question per pull request, addressed to the operator named in `addressees` (empty means addressed to nobody), keyed on `key` so it is asked once; the tick asks and never merges, closes, comments on or gates anything",
    compose: "name the pull request, how long it has been open and what merging it would unblock -- merging it IS the ruling and closing it IS the refusal, so it needs a decision rather than a review",
    pulls: .}' 2>/dev/null || echo '{}')

if [ "$open_n" -eq 1 ]; then
    event="a pull request opened for the operator is still unanswered — merging it is the ruling, closing it is the refusal"
else
    event="${open_n} pull requests opened for the operator are still unanswered — merging them is the ruling, closing them is the refusal"
fi

emit ok "" "$summary" "$needs" "$event"
