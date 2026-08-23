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
# Usage:
#   question-liveness.sh --key <content-key> --step <owning-step-id> --run <path|->
# Output: one JSON line
#   {"liveness": "live|settled|unknown", "key": "...", "step": "...", "reason": ""}
#
#   live     the owning step ran and raised this key again this tick
#   settled  the owning step ran, reported ok, and did not raise it
#   unknown  the step is absent from the run, degraded, blocked, or the run is unreadable

set -eu

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

emit() {
    printf '{"liveness": "%s", "key": "%s", "step": "%s", "reason": "%s"}\n' \
        "$1" "$KEY" "$STEP" "${2:-}"
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
if printf '%s' "$ROW" | jq -e --arg k "$KEY" '(.needs_agent // []) | tostring | contains($k)' >/dev/null 2>&1; then
    emit live
fi

emit settled
