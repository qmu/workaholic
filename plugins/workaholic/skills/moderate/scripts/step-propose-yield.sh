#!/bin/sh -eu
# Step 35 — a RUN of propose ticks that originated nothing.
#
# WHY THIS STEP EXISTS (2026-09-19, ticket `20260919093809`, operator's ask issue #907 item 1:
# *a zero-proposal tick is a finding, not an outcome*). MEASURED on a consuming repository,
# 2026-09-02: 64 consecutive `/propose` ticks each ended `{"proposed": 0}` beside eight open
# inbound items and an empty queue, and every one of them was reported as "no change".
#
# The claim was re-established against this tree before the step was written and it holds.
# `/propose`'s own outcome for a tick that originates nothing is a line in its run report
# (`propose/reference/loop.md` step 1), and that skill says three times over why the report
# cannot carry a finding: *this report is read by nobody on the day it matters*. The surface a
# person reads is `/moderate`, and its registry carried NO step reading whether propose ticks
# produce anything. The nearest one, `step-blocked-tick.sh`, asks a DIFFERENT question — did a
# propose tick open and never close — and a tick that opened, surveyed, refused every direction
# and closed cleanly is the healthy case by that reading. Sixty-four of them read identically to
# sixty-four idle hours. `step-blocked-tick.sh` is deliberately NOT widened: *never closed* and
# *closed having originated nothing* are two questions, and one step answering both is how the
# two drift (this repository's own recorded rule for `overdue` versus `pace`).
#
# THE LOG ALREADY CARRIES THE OUTCOME, so this step adds no writer, no second store, no cursor
# and no field on any artifact. Established by reading the tree rather than assumed:
# `log-read.sh --owner propose` answers ZERO entries here — nothing in the plugin writes the
# documented `propose-open`/`propose-close` pair — while
# `log-read.sh --owner loop --step-prefix loop-finish-propose` answers 16 entries whose summary
# is the worker's own structured result, e.g.
# `{"executed":true,"outcome":"propose:proposed_0:past_target_date", ...}`. That line is written
# by the one writer (`log-append.sh`) through the finish seam
# (`runtime/scripts/coordinator.sh`, `work/scripts/codex-loop.sh`), once per propose tick that
# executed. So this step READS; it establishes nothing new.
#
# THE CLASSIFICATION IS DECLARED ONCE AND COMPOSED HERE, NEVER SPELLED (2026-09-20, ticket
# `20260920014751`). It used to be enumerated in this file, on the READER's side, where it could
# only ever be a guess about what writers produce — this header said so — and the guess was
# wrong on ordinary traffic: MEASURED 2026-09-20 over this checkout's newest two day files,
# `completed`, `published_and_merged` and `published` were all outside it, so the step answered
# `degraded` every run and never once reached its finding.
# `runtime/scripts/outcome-classify.sh` is now the one declaration and the one reading. It
# answers four classes per entry — `originated`, `nothing`, `unmeasured` (a recognised terminal
# word carrying no yield information, `worker-result.schema.json`'s own enum among them) and
# `unclassified` (a token outside every set, or a summary that is not JSON) — reading `.outcome`
# and NEVER `.reason`, per segment of a composite outcome, with any originated segment winning.
# This step counts what that reading answers and spells no token.
#
# AN UNREAD ENTRY HOLDS THE FINDING, BUT ONLY WHEN THE FINDING IS THE CLAIM IT WOULD BLOCK.
# The old order tested `unclassified` BEFORE `originated`, so one unreadable entry suppressed a
# conclusion it cannot weaken: *one tick originated something* is established by that one tick
# whatever else the window holds. The rule this file has always stated is narrower than the code
# was — one entry this step could not read is enough to make *EVERY tick originated nothing* a
# claim it has not established — so the unread entries are consulted exactly where that claim is
# about to be made, and `originated > 0` answers `ok` first. A degraded read is still never a
# finding (`log-read.sh`'s own header: `readable: false` is not zero ticks), and
# `outcome_unclassified` keeps its name beside the new `outcome_unmeasured`, because *the writer
# could not say* and *the reader could not read* send a person to different places.
#
# THE BOUND IS DERIVED, NOT PICKED (the ticket's own gate: a bare number with no derivation does
# not pass). The finding is a RUN of originate-nothing ticks, never a single one, and the two
# terms both come from readings that already exist:
#   * the WINDOW is the newest two day files, `step-blocked-tick.sh`'s own bound applied
#     unchanged — two is what a UTC midnight rollover needs to hold the previous ticks, and the
#     log grows forever so an unbounded walk gets more expensive every day;
#   * a RUN is *every propose finish that window holds, and more than one of them* — the same
#     structural *a condition that has outlived a further tick* bound the sibling step uses for
#     its own subject. A single originate-nothing tick is the ordinary case and raises nothing.
# No new constant, no environment variable and no stored timestamp is introduced.
#
# THE FINDING IS THE GATING, NOT THE SILENCE. It composes `propose/scripts/survey-strategies.sh`
# for the CURRENT refusal set (`.refused[].reason`) so a person reads *four directions held by
# `open_proposal`* rather than *propose is quiet*. It derives no refusal of its own and adds no
# word to that vocabulary; a survey that could not be run is `survey_unreadable` and raises
# nothing, because a finding naming no cause is the silent line this step exists to replace.
#
# THE SUMMARY CARRIES NO COUNT, NO TICK ID AND NO TIMESTAMP — a correctness requirement rather
# than a preference. The root calls a step changed when its summary differs from the same step's
# an hour ago, and the window's entry count grows every tick, which would mark this step changed
# hourly by construction. Two keyed roots have already been retired here for exactly that. The
# counts ride `needs_agent`, which is the question's body and not the root's line.
#
# IT REPORTS AND NEVER ORIGINATES. The temptation is to let the finding open the proposal the
# gates refused; that is refused by name (`rules/workaholic.md`, *What May Originate a Mission* —
# only a human's ask or a human-authored strategy may). It lifts no gate, files no ticket, closes
# nothing and touches no claim. It asks once, keyed on its own subject so `condition-age.sh` can
# age it, through the existing ask seam and the existing asked-once gate.
#
# Usage: step-propose-yield.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
LOG_READ="${SCRIPT_DIR}/log-read.sh"
SURVEY="${SCRIPT_DIR}/../../propose/scripts/survey-strategies.sh"
CLASSIFY="${SCRIPT_DIR}/../../runtime/scripts/outcome-classify.sh"

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
    printf '{"step": "propose-yield", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

[ -f "$LOG_READ" ] || emit degraded no_log_reader "log-read.sh is not present beside this skill"
[ -f "$CLASSIFY" ] || emit degraded no_outcome_classifier "the one outcome declaration is not present beside this skill"

DIR="${ROOT}/.workaholic/moderations"
[ -d "$DIR" ] || emit skipped no_log_area "this repository keeps no tick log; there is no propose tick to read"

# The newest two day files, named lexically. `--since` takes the earlier of the two.
since=$(ls "$DIR" 2>/dev/null | sed -n 's/^\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)\.md$/\1/p' | sort | tail -2 | head -1)
[ -n "$since" ] || emit skipped no_log_area "the tick log holds no day file yet"

out=$(sh "$LOG_READ" --root "$ROOT" --since "$since" --owner loop --step-prefix loop-finish-propose 2>/dev/null || true)
if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    emit degraded log_unreadable "the tick log returned nothing this step could parse"
fi
if ! printf '%s' "$out" | jq -e '.read == true' >/dev/null 2>&1; then
    why=$(printf '%s' "$out" | jq -r '.reason // "unreadable"' 2>/dev/null || printf unreadable)
    emit degraded "$why" "the propose tick log could not be read: ${why}"
fi

# One reading, four counts. The token sets are the CLASSIFIER's; this step spells none of them.
# Each summary goes in as its own line, which is what it already is in the day file.
classes=$(printf '%s' "$out" | jq -r '.entries[].summary' 2>/dev/null \
    | sh "$CLASSIFY" 2>/dev/null || printf '')
counts=$(printf '%s' "$classes" | jq -s -c '
      {total: length,
       nothing:      (map(select(.class == "nothing")) | length),
       originated:   (map(select(.class == "originated")) | length),
       unmeasured:   (map(select(.class == "unmeasured")) | length),
       unclassified: (map(select(.class == "unclassified")) | length)}' 2>/dev/null || printf '')
[ -n "$counts" ] || emit degraded log_unreadable "the propose finish entries could not be classified"

total=$(printf '%s' "$counts" | jq -r '.total' 2>/dev/null || printf 0)
nothing=$(printf '%s' "$counts" | jq -r '.nothing' 2>/dev/null || printf 0)
originated=$(printf '%s' "$counts" | jq -r '.originated' 2>/dev/null || printf 0)
unmeasured=$(printf '%s' "$counts" | jq -r '.unmeasured' 2>/dev/null || printf 0)
unclassified=$(printf '%s' "$counts" | jq -r '.unclassified' 2>/dev/null || printf 0)

[ "$total" -gt 0 ] || emit ok "" "the log window holds no propose tick that finished; nothing to read for a yield"

# ONE TICK THAT ORIGINATED SETTLES IT, and it settles it whatever else the window holds — an
# entry nobody could read cannot unmake a tick that demonstrably produced something. This is
# tested FIRST for that reason; the unread entries are consulted below, where the claim they
# genuinely block is about to be made.
if [ "$originated" -gt 0 ]; then
    emit ok "" "the propose ticks in the log window include one that originated something"
fi

# From here the step is about to claim that EVERY tick originated nothing, and an entry it could
# not read makes that a claim it has not established. Two reasons, never one: `unclassified` is
# a token outside the declaration or a summary that is not JSON — the reader could not read it —
# while `unmeasured` is a recognised terminal word that carries no yield at all, which is the
# WRITER being unable to say. They send a person to different places.
if [ "$unclassified" -gt 0 ]; then
    emit degraded outcome_unclassified "a propose tick's recorded outcome is outside the declared token set, or its summary is not JSON; no yield was judged"
fi

if [ "$unmeasured" -gt 0 ]; then
    emit degraded outcome_unmeasured "a propose tick recorded a terminal outcome that carries no yield information; no yield was judged"
fi

# `nothing == total` from here. A single such tick is the ordinary case.
if [ "$total" -lt 2 ]; then
    emit ok "" "one propose tick in the log window originated nothing, which is the ordinary case"
fi

# The finding is the GATING. The survey is the only source of the refusal words; it derives none.
survey=$(sh "$SURVEY" 2>/dev/null || true)
if [ -z "$survey" ] || ! printf '%s' "$survey" | jq -e '.ok == true' >/dev/null 2>&1; then
    emit degraded survey_unreadable "every propose tick in the log window originated nothing, and the refusal set that held them could not be read"
fi

words=$(printf '%s' "$survey" | jq -r '[.refused[]?.reason] | unique | join(", ")' 2>/dev/null || printf '')
[ -n "$words" ] || words="no refusal recorded on any direction"

needs=$(jq -cn --arg words "$words" --arg total "$total" \
    '{action: "ask_whether_the_originating_routine_should_still_be_refusing",
      bound: "one question, keyed on `key`. The step asks and nothing else — it opens no proposal, files no ticket, lifts no gate, closes nothing and touches no claim. `rules/workaholic.md`, *What May Originate a Mission*, permits only a human'"'"'s ask or a human-authored strategy to originate.",
      compose: "say that every propose tick the log window holds closed having originated nothing, name how many, and name the refusal words the survey reports as holding the directions. Do NOT propose the move the gates refused; ask whether the refusals are the intended state.",
      ticks: ($total | tonumber), refusals: $words,
      key: "propose-yield:originated-nothing"}' 2>/dev/null || echo '{}')

emit blocked originated_nothing \
    "every propose tick the log window holds closed having originated nothing; directions held by: $(json_escape "$words")" \
    "$needs" \
    "every propose tick in the window originated nothing; directions held by: $(json_escape "$words")"
