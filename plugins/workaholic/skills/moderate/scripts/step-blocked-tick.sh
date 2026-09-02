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

DIR="${ROOT}/.workaholic/moderations"
[ -d "$DIR" ] || emit skipped no_log_area "this repository keeps no tick log; there is no tick to read"

# The newest two day files, named lexically. `--since` takes the earlier of the two.
since=$(ls "$DIR" 2>/dev/null | sed -n 's/^\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)\.md$/\1/p' | sort | tail -2 | head -1)
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

# AND THE SECOND SUBJECT: THE PROPOSE TICK (2026-09-02, ticket `20260902043117`). `[Propose]` is the
# routine that ORIGINATES the loop's work, and it was the one measured parked hourly on a permission
# prompt — while leaving no trace anywhere, because it wrote no log at all. A parked tick spends its
# fire, produces nothing and reads as scheduled and healthy; a person noticed days later.
#
# It is read HERE rather than in a step of its own because the question is identical — *this opened
# and never closed* — and the log is already in hand from the one read above. A sibling step would
# be a second reader of one file answering one question, which is how two readings start to
# disagree. Same structural bound as the moderate subject: the tick BEFORE LAST, never a threshold,
# so a propose tick still running when the next one starts is never called stopped.
#
# The pair it looks for is `propose-open` / `propose-close`, which `/propose` writes and nothing
# else does. A repository whose propose tick predates that contract simply has no `propose-open`
# line, and this arm stays silent rather than reporting a stop it cannot see.
propose_subject=$(printf '%s' "$out" | jq -r --arg now "$TICK" \
    '[.entries[] | select(.step == "propose-open") | .tick] | unique | reverse
     | map(select(. != $now)) | .[1] // ""' 2>/dev/null || true)

if [ -z "$subject" ] && [ -z "$propose_subject" ]; then
    emit ok "" "the log holds no tick before last yet; nothing to read for a stop"
fi

opened=0; closed=0; reached=0
if [ -n "$subject" ]; then
    opened=$(printf '%s' "$out" | jq -r --arg t "$subject" \
        '[.entries[] | select(.tick == $t and .step == "open-log")] | length' 2>/dev/null || printf 0)
    closed=$(printf '%s' "$out" | jq -r --arg t "$subject" \
        '[.entries[] | select(.tick == $t and .step == "human-checkin")] | length' 2>/dev/null || printf 0)
    reached=$(printf '%s' "$out" | jq -r --arg t "$subject" \
        '[.entries[] | select(.tick == $t)] | length' 2>/dev/null || printf 0)
fi

# THE PROPOSE ARM, ANSWERED FIRST BECAUSE IT IS COMPOSED THE SAME WAY AND ASKED THE SAME ONCE.
# `propose-close` is the closing signal for the same reason `human-checkin` is the moderate one: it
# is the LAST line the propose tick writes, and unlike a persist it is written before the push
# rather than after it, so a healthy tick's closing line really does reach the branch.
propose_needs=""
propose_event=""
propose_summary=""
if [ -n "$propose_subject" ]; then
    p_closed=$(printf '%s' "$out" | jq -r --arg t "$propose_subject" \
        '[.entries[] | select(.tick == $t and .step == "propose-close")] | length' 2>/dev/null || printf 0)
    p_reached=$(printf '%s' "$out" | jq -r --arg t "$propose_subject" \
        '[.entries[] | select(.tick == $t) | .step | select(startswith("propose-"))] | length' 2>/dev/null || printf 0)
    if [ "$p_closed" -gt 0 ]; then
        propose_summary="the propose tick before last opened and closed"
    else
        p_last=$(printf '%s' "$out" | jq -r --arg t "$propose_subject" \
            '[.entries[] | select(.tick == $t) | .step | select(startswith("propose-"))] | last // "propose-open"' 2>/dev/null || printf propose-open)
        propose_needs=$(jq -cn --arg tick "$propose_subject" --arg last "$p_last" --arg reached "$p_reached" \
            '{action: "ask_about_a_propose_tick_that_never_closed",
              bound: "one question, keyed on `key`, exactly as the moderate arm is. The step asks and nothing else — it re-runs no tick, files no issue and touches no claim. Addressed to nobody: a stopped tick is a fact about the repository.",
              compose: "say that the propose tick opened and never closed, naming the tick id and the last propose step it recorded. The REASON is not on the base by construction — the record that would carry it is the one the stop prevented — so do not guess one. `[Propose]` is the routine that originates the loop'"'"'s work, so a stopped one means no new direction was proposed that hour.",
              tick: $tick, last_step: $last, steps_recorded: ($reached | tonumber),
              key: ("blocked-tick:propose:" + $tick)}' 2>/dev/null || echo '{}')
        propose_event="a propose tick opened and never closed"
        propose_summary="the propose tick before last opened and never closed"
    fi
fi

# THE MODERATE HALF'S OWN SENTENCE, SAID ONLY WHERE THERE IS A TICK TO SAY IT ABOUT. With a
# propose subject and no moderate one — a log that carries propose lines and no moderate tick
# before last — asserting *the tick before last opened and closed* would report a reading this
# step never made, which is the collapse every other reader here is written against.
if [ -n "$subject" ]; then
    moderate_summary="the tick before last opened and closed; ${reached} step(s) recorded"
else
    moderate_summary="the log holds no moderate tick before last"
fi

if [ -z "$subject" ] || [ "$opened" -eq 0 ] || [ "$closed" -gt 0 ]; then
    # The moderate arm is healthy (or has nothing to say). Either it never opened, or it closed,
    # or there is no tick before last — and a step with no event renders no root line. The propose
    # arm is still reported on its own terms.
    if [ -n "$propose_needs" ]; then
        emit ok "" "${propose_summary}" "$propose_needs" "$propose_event"
    fi
    if [ -n "$propose_summary" ]; then
        emit ok "" "${moderate_summary} — ${propose_summary}"
    fi
    emit ok "" "${moderate_summary}"
fi

last_step=$(printf '%s' "$out" | jq -r --arg t "$subject" \
    '[.entries[] | select(.tick == $t) | .step] | last // "open-log"' 2>/dev/null || printf open-log)

needs=$(jq -cn --arg tick "$subject" --arg last "$last_step" --arg reached "$reached" \
    '{action: "ask_about_a_tick_that_never_closed",
      bound: "one question, keyed on `key` so a stopped hour costs one question however many later ticks see it. The step asks and nothing else — it re-runs no tick, touches no claim and lifts no gate. Addressed to nobody: a stopped tick is a fact about the repository and its cause is not on the base.",
      compose: "say that this tick opened and never closed, naming the tick id, how many steps it recorded and the last one it reached. Say plainly that the REASON it stopped is not recoverable from the base — the record that would carry it is the one the stop prevented — so do not guess one. The likeliest cause on record is a run waiting on a prompt nobody was there to answer (`rules/interaction.md`, *An unattended run never waits for a person*), and the run itself is readable in the session list.",
      tick: $tick, last_step: $last, steps_recorded: ($reached | tonumber),
      key: ("blocked-tick:" + $tick)}' 2>/dev/null || echo '{}')

if [ -n "$propose_needs" ]; then
    emit ok "" "the tick before last opened and never closed; ${reached} step(s) recorded — ${propose_summary}" \
        "${needs},${propose_needs}" "a tick opened and never closed, and so did a propose tick"
fi
emit ok "" "the tick before last opened and never closed; ${reached} step(s) recorded" \
    "$needs" "a tick opened and never closed"
