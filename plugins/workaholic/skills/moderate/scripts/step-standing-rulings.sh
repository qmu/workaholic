#!/bin/sh -eu
# Step — the standing rulings, drafted as one pull request instead of asked hourly.
#
# WHY THIS STEP EXISTS (2026-08-28). Two rulings stand that the loop cannot make itself:
# which direction an unattributed mission answers, and which account an unmapped address
# belongs to. Both were surfaced as an hourly QUESTION — `direction-arrived:<slug>` and
# `undrivable-unit:<path>` — and both of those questions name a repair the operator must
# perform BY HAND on `main`: editing a mission's `feedback:` line, or completing a line in
# `.claude/git-identities`. That is the one act this repository still left to a person
# editing the base directly, and it is exactly what `amend.sh` was admitted to remove for
# the strategy artifact. Drafted instead, MERGING is the ruling and CLOSING is the refusal.
#
# IT DRAFTS AT MOST ONE OPEN RULING PULL REQUEST AT A TIME, in `list-open-proposals.sh`'s
# shape: derived from the open pull requests the loop itself opened, with NO CURSOR AND NO
# STORED STATE. Two competing diffs about the same subjects is the failure the brake exists
# to prevent, and the brake is deliberately read off GitHub rather than stored — a cursor is
# a second source of truth about what is in flight, and this repository has refused one at
# every equivalent seam.
#
# IT WRITES NOTHING BUT ITS OWN TICK-LOG LINE. The judgement is the run's — which direction
# a mission answers is a reading no script may make — so the candidate set goes back in
# `needs_agent` and the agent supplies one `--judgement <subject>=<answer>` per subject it
# can judge and calls `draft-standing-rulings.sh`. Every artifact write happens in the
# publish tree that script opens, exactly as `closable-missions` hands its tree-writing act
# to the agent rather than performing it inside `run.sh`.
#
# ITS `event` IS ALWAYS EMPTY, and that is a deliberate divergence from the steps beside it
# — `step-unanswered-asks.sh`'s reason, for the same architecture. At the moment `run.sh`
# reads this line NOTHING HAS BEEN DRAFTED YET: the agent acts on `needs_agent` only after
# `run.sh` returns, so any event here would be a claim about an act this step has not taken.
# A tick that drafted nothing therefore renders no root line, which is what the requirement
# asks for; the drafted pull request reaches the operator as a pull request, which is the
# surface it is addressed to.
#
# A DEGRADED READ DRAFTS NOTHING and is named. A ruling that could not be read is not a
# ruling, and an unreadable brake is not a brake.
#
# IT NEVER REACHES `plan-units.sh` — `undrivable-units`' rule, first recorded by
# `closable-missions`: the survey reaches the mission readers, which carry the living
# migrations and **stage** what they converge, and a step whose contract is *writes nothing*
# may not reach it through something that writes.
#
# Usage: step-standing-rulings.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
LIST="${SCRIPT_DIR}/list-standing-rulings.sh"
OPEN="${SCRIPT_DIR}/list-open-rulings.sh"

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
    printf '{"step": "standing-rulings", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": ""}\n' \
        "$1" "$2" "$3" "${4:-}"
    exit 0
}

command -v jq >/dev/null 2>&1 || emit degraded jq_unavailable "jq is not on PATH, so no ruling could be read"
[ -f "$LIST" ] || emit degraded no_rulings_reader "list-standing-rulings.sh is not present beside this step"
[ -f "$OPEN" ] || emit degraded no_brake_reader "list-open-rulings.sh is not present beside this step"

# --- 1. The brake, first: an unreadable one drafts nothing ---------------------------
open_out=$( ( cd "$ROOT" && sh "$OPEN" ) 2>/dev/null || true )
if [ -z "$open_out" ] || ! printf '%s' "$open_out" | jq -e . >/dev/null 2>&1; then
    emit degraded brake_unreadable "the open ruling pull requests could not be read, so nothing is drafted"
fi
if [ "$(printf '%s' "$open_out" | jq -r '.ok // false')" != "true" ]; then
    emit degraded "brake_$(printf '%s' "$open_out" | jq -r '.reason // "unreadable"')" \
        "the open ruling pull requests could not be read, so nothing is drafted"
fi
open_n=$(printf '%s' "$open_out" | jq -r '(.rulings // []) | length')
if [ "${open_n:-0}" -gt 0 ]; then
    numbers=$(printf '%s' "$open_out" | jq -r '[.rulings[].number | tostring] | join(", #")')
    emit ok "" "a ruling pull request is already open (#${numbers}); nothing drafted"
fi

# --- 2. The candidate set, from the one reader that owns it --------------------------
rulings=$( ( cd "$ROOT" && sh "$LIST" ) 2>/dev/null || true )
if [ -z "$rulings" ] || ! printf '%s' "$rulings" | jq -e . >/dev/null 2>&1; then
    emit degraded rulings_unreadable "the standing rulings could not be read, so nothing is drafted"
fi
if [ "$(printf '%s' "$rulings" | jq -r '.readable // false')" != "true" ]; then
    emit degraded "$(printf '%s' "$rulings" | jq -r '.reason // "rulings_unreadable"' | tr -d '"')" \
        "the standing rulings could not be read, so nothing is drafted"
fi

n=$(printf '%s' "$rulings" | jq -r '.count // 0')
[ "${n:-0}" -gt 0 ] || emit ok "" "no standing ruling: nothing is unattributed and every address the tree uses is named"

needs=$(printf '%s' "$rulings" | jq -c '{action: "judge_each_standing_ruling_and_draft_them_as_one_pull_request",
    bound: "for an `attribution` supply the strategy slug the mission answers, judged against the active strategies own Aims; for an `identity_mapping` supply the GitHub login the address belongs to, judged against the git history. A subject you cannot judge is LEFT OUT — it keeps its own hourly question and reaches no writer. Then run moderate/scripts/draft-standing-rulings.sh with one --judgement <subject>=<answer> per judged subject. Never judge on title similarity: a machine only ever CARRIES a ruling.",
    candidates: (.rulings // [])}' 2>/dev/null || echo '{}')

emit ok "" "${n} standing ruling(s) to judge and draft" "$needs"
