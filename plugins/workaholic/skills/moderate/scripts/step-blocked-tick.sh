#!/bin/sh -eu
# Step — a tick that opened and never closed.
#
# WHY THIS STEP EXISTS (2026-08-31, mission `stop-an-unattended-tick-from-waiting-on-a-person`).
# An opening on the base with no closing is the signature of a tick that STOPPED, and nothing read
# for it. Measured: three consecutive ticks sat at `requires_action` waiting on a permission prompt
# a routine has nobody to answer, and the record that would have shown it is the record the stop
# prevents — `persist-log.sh` was the tick's closing act, so a dead tick left the base untouched.
# `run.sh`'s opening persist put the opening there; this reads for it.
#
# IT COMPOSES `log-read.sh` AND ADDS NO PARSER. The log has exactly one reader and this is not a
# second one: the step asks it for entries and groups them by the tick id it already returns. No
# cursor, no store, no field on any artifact, and nothing written anywhere but this step's own log
# line, which `run.sh` writes.
#
# WHAT "CLOSED" MEANS, AND WHY IT IS NOT THE PERSIST. The tempting signal is the closing persist's
# own `persist-log` line, and it is WRONG: `run.sh` writes that line AFTER the push, so it never
# reaches the base on the tick that wrote it — it arrives only if the agent persists again, which
# a tick with an empty `needs_agent` has no reason to do. A healthy tick would therefore read as
# stopped. The signal used instead is a **`human-checkin` line**: it is the last member of `STEPS`
# and is deliberately exempt from `--deadline-seconds`, so a tick that reached the end of its run
# always logged it. The coupling is stated here rather than derived — a step that read `run.sh`'s
# own `STEPS` to find the last one would be inspecting a plugin script to find something out
# (`rules/shell.md`), and a second definition of *the tick's closing step* is what would drift.
#
# WHICH TICK, AND WHY NOT THE PREVIOUS ONE. A tick still RUNNING when the next one starts also has
# an opening and no closing, and the two are distinguishable only by time. Rather than tune a
# threshold, the bound is structural: this reads **the tick before last** — the second-newest tick
# other than this one — which has had a full extra hour to finish. A run that is merely slow is
# not reported; one that has outlived a whole further tick is. The cost is stated rather than
# hidden: a stopped tick is named one hour later than the earliest possible moment, and the
# measured failure lasted hours.
#
# ONE QUESTION PER STOPPED HOUR. Keyed `blocked-tick:<tick-id>` through the existing gate, so a
# tick that stopped costs exactly one question however many later ticks see it. `ask-question.sh`
# is untouched — no key, cap or hold moves.
#
# IT SAYS WHAT IS KNOWN AND NO MORE. *This tick opened and never closed.* The reason it stopped is
# not on the base by construction — that is the whole shape of the failure — so the question names
# the tick, the step it reached, and nothing about why.
#
# THE WALK IS BOUNDED. The newest **two** day files, selected lexically from names that sort
# correctly by construction (`condition-age.sh`'s bound, narrowed): two is what a UTC midnight
# rollover needs to hold the previous two ticks, and the log grows forever, so an unbounded walk
# gets more expensive every day.
#
# THE SUMMARY CARRIES NO TICK ID AND NO TIMESTAMP, a correctness requirement rather than a
# preference (`step-stalled-units.sh`'s header records the measurement): the root calls a step
# changed when its summary differs from the same step's an hour ago, and a tick id moves every
# tick, which would mark this step changed hourly by construction.
#
# IT ASKS AND NOTHING ELSE: it re-runs no tick, writes no log entry of its own, touches no claim,
# reaches no `plan-units.sh` (that survey stages what its living migrations converge), and never
# consults the running identity — a stopped tick is a fact about the repository, and this tick is
# repository-scoped.
#
# Usage: step-blocked-tick.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
LOG_READ="${SCRIPT_DIR}/log-read.sh"

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
    printf '{"step": "blocked-tick", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

[ -f "$LOG_READ" ] || emit degraded no_log_reader "log-read.sh is not present beside this skill"

# THE DAY LISTING COMES FROM THE ONE RESOLVER (2026-08-31, mission
# `take-the-moderation-tick-s-log-off-main`). This step walked the directory itself; with the
# log on its own ref that walk sees only what THIS container appended, so a tick that stopped
# in an earlier container -- the only kind this step exists to notice -- would be invisible.
days_out=$(sh "$LOG_READ" --root "$ROOT" --list-days 2>/dev/null || true)
# A READER THAT ANSWERS SOMETHING THIS STEP CANNOT PARSE IS A DEGRADATION, never a quiet
# hour -- the same collapse this step exists to remove one level up. Checked on the LISTING
# too, not only on the entries read below: the listing is now where the step first touches
# the log, so a reader broken there would otherwise fall through to `no day file yet`.
if [ -z "$days_out" ] || ! printf '%s' "$days_out" | jq -e . >/dev/null 2>&1; then
    emit degraded log_unreadable "the tick log returned nothing this step could parse"
fi
if printf '%s' "$days_out" | jq -e '.read == false' >/dev/null 2>&1; then
    why=$(printf '%s' "$days_out" | jq -r '.reason // "unreadable"' 2>/dev/null || printf unreadable)
    case "$why" in
        no_log_area) emit skipped no_log_area "this repository keeps no tick log; there is no tick to read" ;;
        *) emit degraded "$why" "the tick log could not be read: ${why}" ;;
    esac
fi

# The newest two day files, named lexically. `--since` takes the earlier of the two.
since=$(printf '%s' "$days_out" | jq -r '.days[]?' 2>/dev/null | sort | tail -2 | head -1)
[ -n "$since" ] || emit skipped no_log_area "the tick log holds no day file yet"

out=$(sh "$LOG_READ" --root "$ROOT" --since "$since" 2>/dev/null || true)
if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    emit degraded log_unreadable "the tick log returned nothing this step could parse"
fi
if printf '%s' "$out" | jq -e '.read == false' >/dev/null 2>&1; then
    why=$(printf '%s' "$out" | jq -r '.reason // "unreadable"' 2>/dev/null || printf unreadable)
    emit degraded "$why" "the tick log could not be read: ${why}"
fi

# The tick before last: distinct ticks newest-first, this one dropped, the second taken.
subject=$(printf '%s' "$out" | jq -r --arg now "$TICK" \
    '[.entries[].tick] | unique | reverse | map(select(. != $now)) | .[1] // ""' 2>/dev/null || true)

if [ -z "$subject" ]; then
    emit ok "" "the log holds no tick before last yet; nothing to read for a stop"
fi

opened=$(printf '%s' "$out" | jq -r --arg t "$subject" \
    '[.entries[] | select(.tick == $t and .step == "open-log")] | length' 2>/dev/null || printf 0)
closed=$(printf '%s' "$out" | jq -r --arg t "$subject" \
    '[.entries[] | select(.tick == $t and .step == "human-checkin")] | length' 2>/dev/null || printf 0)
reached=$(printf '%s' "$out" | jq -r --arg t "$subject" \
    '[.entries[] | select(.tick == $t)] | length' 2>/dev/null || printf 0)

if [ "$opened" -eq 0 ] || [ "$closed" -gt 0 ]; then
    # Either it never opened (nothing this step can say about it) or it closed. Both are the
    # healthy reading, and a step with no event renders no root line.
    emit ok "" "the tick before last opened and closed; ${reached} step(s) recorded"
fi

last_step=$(printf '%s' "$out" | jq -r --arg t "$subject" \
    '[.entries[] | select(.tick == $t) | .step] | last // "open-log"' 2>/dev/null || printf open-log)

needs=$(jq -cn --arg tick "$subject" --arg last "$last_step" --arg reached "$reached" \
    '{action: "ask_about_a_tick_that_never_closed",
      bound: "one question, keyed on `key` so a stopped hour costs one question however many later ticks see it. The step asks and nothing else — it re-runs no tick, touches no claim and lifts no gate. Addressed to nobody: a stopped tick is a fact about the repository and its cause is not on the base.",
      compose: "say that this tick opened and never closed, naming the tick id, how many steps it recorded and the last one it reached. Say plainly that the REASON it stopped is not recoverable from the base — the record that would carry it is the one the stop prevented — so do not guess one. The likeliest cause on record is a run waiting on a prompt nobody was there to answer (`rules/interaction.md`, *An unattended run never waits for a person*), and the run itself is readable in the session list.",
      tick: $tick, last_step: $last, steps_recorded: ($reached | tonumber),
      key: ("blocked-tick:" + $tick)}' 2>/dev/null || echo '{}')

emit ok "" "the tick before last opened and never closed; ${reached} step(s) recorded" \
    "$needs" "a tick opened and never closed"
