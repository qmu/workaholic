#!/bin/sh -eu
# Is the subject of an already-asked question still live, or has it settled?
#
# WHY (2026-08-23). `ask-question.sh`'s `already_asked` gate reads one fact — was this key
# asked before — and refuses a second ask. That is what it was fixed to do and it must keep
# doing it. What it cannot express is the difference between **asked and settled** and
# **asked and still blocking**: a question whose blocker cleared itself and one that has
# held a unit for a week are the same state at the gate. The tick already re-derives every
# finding each hour, so the fact needed to tell them apart is produced every run and then
# discarded.
#
# THE ANSWER IS RE-DERIVED, NOT STORED (the ticket's step 3, ruled here). The tick's own
# step output is the source: no new log field, no new store, nothing to keep in sync, and
# no line of the append-only log rewritten. The alternative — carrying liveness on the log
# line — is durable but adds a field the log did not have, and the measurement did not need
# it: every question this tick can ask comes from a step that ran this tick, so that step's
# `needs_agent` is exactly the set of subjects still live.
#
# IT NEVER SCANS THE REPOSITORY. The Considerations are explicit: re-reading the tree per
# asked key turns an hourly tick into a scan. This reads one JSON document the caller
# already has.
#
# THE OWNING STEP IS AN ARGUMENT, NOT A GUESS. The caller composed the question from a
# step's `needs_agent`, so it knows which step raised it. Deriving the step from the key's
# prefix would be a second, fuzzy naming contract (`stalled-unit:` is not the step id
# `stalled-units`), and a wrong guess would answer `settled` about a subject nobody looked
# at — the one answer this script must never invent.
#
# `unknown` IS LOAD-BEARING, NOT A PLACEHOLDER. A step that degraded, or that the deadline
# never reached, cannot report its finding; treating that absence as `settled` would
# re-create the exact silence this mission exists to end. `unknown` never collapses into
# either other answer.
#
# `settled` IS AN ABSENCE, AND `resolution` IS THE POSITIVE READING BESIDE IT (2026-09-18,
# ticket `20260918080734`). `settled` means the step ran and this key was not among the
# strings it raised — which is the right reading for the two consumers it has (the bounded
# re-ask, and the `✅ 解消を確認` confirmation), and is NOT evidence that the premise
# resolved. `reconcile-questions.sh` read it as one and wrote `proved: true` out of it, which
# is an absence of a reading presented as a proof (`drive/reference/claims.md`, *Proofs and
# judgements*). Measured: `inbound-channel-unreadable:<channel>` is composed by the AGENT
# after the step runs, so the owning step can never name it in `needs_agent` and it carries
# only as a substring of the escalation sentence; every key of that class was retired on the
# first tick that reconciled it, while the channel was measurably still unreadable —
# `never_asked` and `retired` in one reading, permanently, because `register` and `asked` are
# both no-ops over a retired row.
#
# SO `resolution` IS ADDITIVE AND `liveness` DOES NOT MOVE. The three liveness words, the
# exact-string match and both existing consumers are byte-identical: a key genuinely absent
# from `needs_agent` cannot be recovered by any matching rule, so narrowing the match would
# move the defect to the next agent-composed key rather than remove it.
#
# A RAISED KEY IS NEVER `proved`. A step that still raises a subject and also names it
# resolved is contradicting itself; raising wins, because the safe direction here is to leave
# the question askable.
#
# Usage:
#   question-liveness.sh --key <content-key> --step <owning-step-id> --run <path|->
# Output: one JSON line
#   {"liveness": "live|settled|unknown", "resolution": "proved|unwitnessed|unknown",
#    "key": "...", "step": "...", "reason": ""}
#
#   live     the owning step ran and raised this key again this tick
#   settled  the owning step ran, reported ok, and did not raise it
#   unknown  the step is absent from the run, degraded, blocked, or the run is unreadable
#
#   proved       the step's row names this key as an exact string in its own `resolved_keys`
#                statement of what it resolved, and does not raise it
#   unwitnessed  the step ran ok/filed and neither raised the key nor named it resolved —
#                the case the retirement used to call proof
#   unknown      every case `liveness` answers `unknown` for

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"

KEY=''
STEP=''
RUN=''
while [ $# -gt 0 ]; do
    case "$1" in
        --key) KEY="${2:-}"; shift 2 ;;
        --step) STEP="${2:-}"; shift 2 ;;
        --run) RUN="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done

RESOLUTION=unknown

emit() {
    printf '{"liveness": "%s", "resolution": "%s", "key": "%s", "step": "%s", "reason": "%s"}\n' \
        "$1" "$RESOLUTION" "$KEY" "$STEP" "${2:-}"
    exit 0
}

[ -n "$KEY" ] || emit unknown no_key
[ -n "$STEP" ] || emit unknown no_step

if [ "$RUN" = "-" ]; then
    DOC=$(cat)
elif [ -n "$RUN" ] && [ -f "$RUN" ]; then
    DOC=$(cat "$RUN")
else
    emit unknown no_run
fi

printf '%s' "$DOC" | jq -e . >/dev/null 2>&1 || emit unknown run_unparseable

# The step's own row in this tick's report. Absent means the deadline never reached it, or
# it is not in `STEPS` — either way nobody looked, which is `unknown`.
ROW=$(printf '%s' "$DOC" | jq -c --arg s "$STEP" '[.steps[]? | select(.step == $s)] | first // empty' 2>/dev/null || true)
[ -n "$ROW" ] || emit unknown step_not_in_run

STATUS=$(printf '%s' "$ROW" | jq -r '.status // ""')
case "$STATUS" in
    ok|filed) ;;
    "")        emit unknown step_status_unreadable ;;
    *)         emit unknown "step_${STATUS}" ;;
esac

# `needs_agent` is the step's own statement of what still needs a person. The key is matched
# as an exact string anywhere in that payload, because each step names its candidates in its
# own shape and this script deliberately learns none of them — what it needs is only whether
# the step raised this subject again.
if printf '%s' "$ROW" | jq -e --arg k "$KEY" 'any((.needs_agent // []) | .. | strings; . == $k)' >/dev/null 2>&1; then
    RESOLUTION=unwitnessed
    emit live
fi

# `resolved_keys` is the step's own statement of what it RESOLVED, matched exactly as
# `needs_agent` is matched above and learned no more deeply. No step is required to emit it:
# until one does, the reading is `unwitnessed` everywhere and the retirement retires nothing,
# which is the honest side of the trade — an open question is visible and re-askable, an
# extinguished one is neither.
if printf '%s' "$ROW" | jq -e --arg k "$KEY" 'any((.resolved_keys // []) | .. | strings; . == $k)' >/dev/null 2>&1; then
    RESOLUTION=proved
else
    RESOLUTION=unwitnessed
fi

emit settled
