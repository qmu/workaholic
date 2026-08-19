#!/bin/sh -eu
# Step 8 — proposals for a strategy. GATED: it emits nothing until the operator rules.
#
# WHY THIS STEP DOES NOT PROPOSE (2026-08-17). Its own mission says it: "every step
# reversing a standing decision is ruled on by the operator or left unbuilt, never
# inferred." Step 8 reverses one. `workaholic:specificate`'s judgment bar states that
# **missions, the queue and commits are constraints, never triggers** — feedback is
# the only input that can originate a proposal — and the retired `[Propose Batch]`
# routine was exactly the state-sweep this step reintroduces, with a recorded
# failure mode of "a channel full of plausible noise". A session cannot both obey
# that bar and quietly build past it, so this step reports the ruling it needs and
# writes nothing.
#
# THREE RULINGS ARE OUTSTANDING, and they are independent:
#   1. Does a strategy become a SECOND legitimate originator (stated in the propose
#      skill, so there is one bar and not two), a narrower bar inside /propose, or
#      nothing at all? The argument FOR is real and is recorded rather than acted
#      on: a strategy is not repository state — it is the operator's own resolved,
#      dated, owned direction, which is much closer to feedback than to a backlog
#      sweep. The argument stays the operator's to accept.
#   2. Which Slack shape? `🟡` is the handoff finish line today and the start post
#      was retired on 2026-08-11 ("a routine posts its finish only"), so the ask's
#      `🟡 Proposing` collides twice. And `workaholic:notify`'s *the prompt is the
#      ceiling* means no session may emit a shape the routine's own prompt does not
#      name — so a shape settled here alone would still be inert.
#   3. What counts as "negative feedback" for the decline lifecycle? A reaction, a
#      token in a reply, a human closing the pull request and a model's reading of a
#      thread have four very different false-positive rates, and an auto-close on a
#      misread reply destroys a proposal nobody rejected. If it is ever built, an
#      EXPLICIT token is the only one of the four whose false-positive rate is a
#      property of the rule rather than of the reader.
#
# TODAY THE POINT IS MOOT AND SAYS SO: the repository holds zero strategies, so the
# honest outcome is `no_strategies` — reported, not silently empty.
#
# Usage: step-strategy-proposals.sh --tick <id> --root <repo-root>
# Output: one JSON line {"step","status","reason","summary","needs_agent":[],"strategies":n,
#          "open_rulings":[...]}

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
STRATEGY="${SCRIPT_DIR}/../../strategy/scripts"
ROOT='.'

while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-}"; shift 2 ;;
        --tick) shift 2 ;;
        *) shift ;;
    esac
done

RULINGS='"does a strategy originate a proposal at all (propose'"'"'s bar says the repository'"'"'s own state never does)", "which Slack shape — 🟡 is the handoff finish line and the start post was retired on 2026-08-11", "what counts as negative feedback for the decline lifecycle"'

if [ ! -x "${STRATEGY}/list.sh" ] && [ ! -f "${STRATEGY}/list.sh" ]; then
    printf '{"step": "strategy-proposals", "status": "degraded", "reason": "no_strategy_reader", "summary": "the strategy list script is missing — the strategy set is unknown this tick", "needs_agent": [], "strategies": -1, "open_rulings": [%s]}\n' "$RULINGS"
    exit 0
fi

out=$(sh "${STRATEGY}/list.sh" 2>/dev/null || true)
count=$(printf '%s' "$out" | sed -n 's/.*"count": *\([0-9][0-9]*\).*/\1/p')
[ -n "$count" ] || count=0

if [ "$count" -eq 0 ]; then
    printf '{"step": "strategy-proposals", "status": "skipped", "reason": "no_strategies", "summary": "no strategies here — nothing for this step to propose under, and no ruling needed yet", "needs_agent": [], "strategies": 0, "open_rulings": [%s]}\n' "$RULINGS"
    exit 0
fi

printf '{"step": "strategy-proposals", "status": "blocked", "reason": "awaiting_operator_ruling", "summary": "%s strategy(ies) present, but proposing under one reverses propose'"'"'s judgment bar — left unbuilt until the operator rules (3 open rulings)", "needs_agent": [], "strategies": %s, "open_rulings": [%s]}\n' \
    "$count" "$count" "$RULINGS"
