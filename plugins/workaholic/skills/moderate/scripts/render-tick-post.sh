#!/bin/sh -eu
# render-tick-post.sh — THE TICK'S OWN VOICE: what changed in this hour, and whether
# that is worth a person's attention at all.
#
# Usage: run.sh ... | render-tick-post.sh --tick <id> [--root <repo-root>] [--questions <n>]
# Output: one JSON object
#   {"post": bool, "reason": "...", "tick": "...", "token": "tick:<id>",
#
# `token` IS NOT PRINTED AT A READER (2026-08-22). It was rendered as a `tick:<id>` line on
# the root until then, and NOTHING EVER SEARCHED IT -- the already-asked ledger matches the
# step id in `.workaholic/moderations/` and reads Slack at no point. The field stays because
# it identifies the tick to any machine consumer that wants it; what left is the line at a
# person. The developer said it plainly and more than once: stop mixing strange ids into Slack.
#    "changes": [{"step","summary","event"}], "change_count": N, "questions": N,
#    "previous_tick": "<id>|", "root_text": "..."}
#
# ═══ WHY THE TICK NEEDED A VOICE OF ITS OWN ═══════════════════════════════════════
#
# Until now this tick had NO root of its own. Nine steps read the repository, wrote the
# tick log, and posted nothing; the tenth replied one question into the thread of the
# item it concerned. That is a good rule for a QUESTION and a bad shape for a shift:
# nobody was assembling "what happened in this hour", so a member had to reconstruct it
# from per-item threads or from the log.
#
# The developer's design (2026-08-21) is a moderator who works business days and business
# hours: each hour it posts what happened, what needs checking and what needs announcing,
# as ONE root, and the questions it has go out as MENTIONED REPLIES INSIDE that root's
# thread. Root = orientation, addressed to nobody. Replies = directed questions, addressed
# by name. Two speech acts, one thread, told apart by position rather than by two routines.
#
# THIS ALSO ANSWERS "should the morning digest fold in": it does not, because the
# orientation it was carrying now happens continuously during working hours instead of
# once at 09:05. `/standup` keeps only what an hourly root cannot say — a dated direction
# approaching its date — and that decision is deliberately left until this root has run.
#
# ═══ WHAT COUNTS AS A CHANGE, AND WHY IT IS DERIVED ═══════════════════════════════
#
# A change is a step whose summary DIFFERS FROM THE SAME STEP'S SUMMARY IN THE PREVIOUS
# TICK. Nothing else. No step gained a field, no step had to classify its own output, and
# no cursor is stored — the previous tick is in the log this tick already keeps.
#
# That rule is the whole reason this can be hourly without becoming wallpaper. `📦 Release
# Preparation` was retired for posting an unchanged answer ten hours running; a diff
# against the last tick cannot do that by construction. A step reporting the same thing
# it reported an hour ago is not news, however alarming its wording.
#
# THE FIRST TICK OF A DAY HAS NO PREVIOUS TICK IN ITS OWN DAY FILE, and the reader spans
# every day file, so the previous tick is genuinely the previous tick and not "the first
# one since midnight". A tick with no predecessor at all reports `no_previous_tick` and
# posts nothing: everything would read as changed, which is the loudest possible first
# impression and the least informative.
#
# ═══ THE POST GATE ════════════════════════════════════════════════════════════════
#
#   post: true   at least one question to ask AND (since 2026-08-22) nothing else
#                required -- a changed step no longer earns a post on its own
#   post: false  reasons: `idle` (nothing changed, nothing to ask), `no_question`
#                (changes, but nothing to ask -- the root carries questions, and with
#                none it is a status line addressed to nobody), `no_previous_tick`,
#                `no_log` (the tick log could not be read — never rendered as idle)
#
# An idle hour says nothing at all. That is not politeness, it is the condition on which
# a recurring post is allowed to exist here at all: the tie goes to silence, and a tick
# that speaks every hour teaches its readers to skip the surface.
#
# A DEGRADED READ IS NOT AN IDLE HOUR. `no_log` is reported separately and posts nothing,
# because a mechanism that could not read must never announce quiet.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
LOG_READ="${SCRIPT_DIR}/log-read.sh"

TICK=''; ROOT='.'; QUESTIONS=0
while [ $# -gt 0 ]; do
    case "$1" in
        --tick)      TICK="${2:-}"; shift 2 ;;
        --root)      ROOT="${2:-}"; shift 2 ;;
        --questions) QUESTIONS="${2:-0}"; shift 2 ;;
        *) shift ;;
    esac
done
case "$QUESTIONS" in ''|*[!0-9]*) QUESTIONS=0 ;; esac

json_escape() {
    # Newlines become `\n`: `root_text` is a multi-line post carried inside a JSON
    # string, and a raw newline there is an invalid control character, not a formatting
    # nicety. Caught by the first change this script ever rendered.
    printf '%s' "$1" \
      | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' \
      | awk 'BEGIN{ORS=""} NR>1{print "\\n"} {print}'
}
emit() {
    printf '{"post": %s, "reason": "%s", "tick": "%s", "token": "tick:%s", "changes": [%s], "change_count": %s, "questions": %s, "previous_tick": "%s", "root_text": "%s"}\n' \
        "$1" "$2" "$(json_escape "$TICK")" "$(json_escape "$TICK")" "$3" "$4" "$QUESTIONS" "$(json_escape "$5")" "$(json_escape "$6")"
    exit 0
}

# THE FIELD PATTERNS TOLERATE WHITESPACE (`": *\""`, not `": \""`). `run.sh` happens to emit
# spaced JSON, and a parser written against one producer's formatting is a parser that breaks
# the first time anything else feeds it — which is exactly how this was caught, by a test
# handing it `JSON.stringify` output with no spaces at all.
INPUT=$(cat 2>/dev/null || true)
[ -n "$TICK" ] || emit false no_tick "" 0 "" ""

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT INT TERM

# This tick's rows, as `step<TAB>summary`. The run's JSON is one object with a `rows`
# array; the fields are read positionally rather than with jq, because every other script
# in this skill runs where jq may be absent.
# `%s\n`, not `%s`: without the trailing newline `sed` emits its last match unterminated
# and the `while read` below silently drops it -- which cost exactly one step's change on
# the first run of this script.
printf '%s\n' "$INPUT" \
  | tr '{' '\n' \
  | sed -n 's/.*"step": *"\([^"]*\)".*"summary": *"\([^"]*\)".*/\1\t\2/p' > "${TMP}/now"

# THE POST-FACING PHRASE, read beside the log-facing summary (2026-08-23). Each root line
# used to be a step's LOG summary rendered verbatim — an audit trail, written for a
# maintainer diagnosing the tick, and it read like one: `1 to judge`, `0 already captured`,
# `0 finding(s) already filed by an earlier tick` are counters that exist only inside the
# tick, and `no new documentation drift` reports that NOTHING happened while being rendered
# as a change. The audit trail is not the wrong artifact; it is the wrong audience.
#
# THE DIFF STILL READS `summary`. A step's log summary is what tells this hour from the last
# one, and it is the richer signal; the event is what a person is shown once the diff has
# decided there is something to show. Diffing the event instead would hide a real change
# behind a phrase that happens to be worded the same.
#
# A STEP WITH NO EVENT RENDERS NO LINE, and this is the independent guard the ticket asks
# for: a step whose finding is "nothing happened" leaves it empty, so it cannot reach the
# root even if the diff calls it changed. A step that has not been given an event yet is
# silent too, deliberately — silence is the safe failure here, and the tick log keeps every
# line regardless.
printf '%s\n' "$INPUT" \
  | tr '{' '\n' \
  | sed -n 's/.*"step": *"\([^"]*\)".*"event": *"\([^"]*\)".*/\1\t\2/p' > "${TMP}/events"

[ -s "${TMP}/now" ] || emit false no_rows "" 0 "" ""

# The previous tick: every tick id in the log that sorts before this one, largest first.
if [ ! -f "$LOG_READ" ]; then emit false no_log "" 0 "" ""; fi
LOG=$(sh "$LOG_READ" --root "$ROOT" 2>/dev/null || true)
case "$LOG" in
    *'"read": true'*) ;;
    *) emit false no_log "" 0 "" "" ;;
esac

PREV=$(printf '%s\n' "$LOG" | tr '{' '\n' | sed -n 's/.*"tick": *"\([^"]*\)".*/\1/p' \
       | sort -u | awk -v t="$TICK" '$0 < t' | tail -n 1)
[ -n "$PREV" ] || emit false no_previous_tick "" 0 "" ""

printf '%s\n' "$LOG" | tr '{' '\n' \
  | sed -n "s/.*\"tick\": *\"${PREV}\".*\"step\": *\"\([^\"]*\)\".*\"summary\": *\"\([^\"]*\)\".*/\1\t\2/p" > "${TMP}/prev"

# THE DIFF IS TAKEN OVER A STABLE FORM, NOT THE RAW SUMMARY (2026-08-22, issue #569).
# A change is a step whose summary differs from the same step's an hour ago, and it was
# a raw string compare. Two steps embed a value that moves on its own inside that text:
# `inbound-sweep` carries an ISO8601 timestamp (`GitHub read since <ts>`) and `doc-drift`
# carries a sha (`no new documentation drift since <sha>`). Both therefore differed on
# every tick BY CONSTRUCTION, so both were always "changed" and the root always posted --
# measured four consecutive hours on a consuming repository, every post reading
# `2 change(s), 0 question(s)` with nothing behind it. That is exactly what this
# derivation exists to make impossible: `📦 Release Preparation` was retired for restating
# an unchanged answer ten hours running, and the header below claims a diff cannot do that.
#
# The normalization strips only values that move WITHOUT the repository moving -- an
# ISO8601 timestamp, a bare hex object name of 7 characters or more, and a clock time.
# Stripping more would hide a real change behind noise, which is the opposite defect and
# the reason this is a short, named list rather than a general scrub.
stabilize() {
    printf '%s' "$1" | sed -E \
        -e 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|z|[+-][0-9]{2}:?[0-9]{2})?/<ts>/g' \
        -e 's/\b[0-9a-f]{7,40}\b/<sha>/g' \
        -e 's/\b[0-9]{2}:[0-9]{2}(:[0-9]{2})?\b/<time>/g'
}

changes=''
count=0
lines=''
# A DELIVERY FAILURE IS THE ONE THING THE CHECK-IN HAS TO SAY (2026-08-28, mission
# `deliver-what-the-loop-already-knows-to-the-person-who-can-act`). The check-in used to be
# skipped outright here, on the sound reasoning that its own summary changing is not news
# about the repository and its questions are already the thread's replies. That holds for a
# tick that DELIVERS. It is false for a tick that reached nobody: with 22 candidates and zero
# delivered, the tick posted nothing at all and total silence was byte-identical to a quiet
# hour, for eight consecutive ticks.
#
# The skip is removed rather than narrowed, because the guard that replaces it already
# exists: **a step with no event renders no line**, and the check-in supplies an event ONLY
# when it was eligible to ask and structurally could not. So every other tick behaves exactly
# as it did — a delivering check-in and a quiet one both supply no event and are dropped
# below, before they can be counted as a change.
delivery_failure=0
TAB=$(printf '\t')
while IFS="$TAB" read -r step summary || [ -n "$step" ]; do
    [ -n "$step" ] || continue
    [ "$step" = "open-log" ] && continue
    was=$(awk -F"$TAB" -v s="$step" '$1 == s { print $2; exit }' "${TMP}/prev")
    [ "$(stabilize "$was")" = "$(stabilize "$summary")" ] && continue
    event=$(awk -F"$TAB" -v s="$step" '$1 == s { print $2; exit }' "${TMP}/events")
    # No event: the step says nothing happened to the repository, or has not been given a
    # post-facing phrase. Either way it is not news, and the log already has its summary.
    [ -n "$event" ] || continue
    changes="${changes:+${changes}, }{\"step\": \"$(json_escape "$step")\", \"summary\": \"$(json_escape "$summary")\", \"event\": \"$(json_escape "$event")\"}"
    lines="${lines}${event}
"
    count=$((count + 1))
    # Set INSIDE the loop, so the third gate below inherits the diff: a check-in whose
    # reading has not changed since the previous tick never reaches here, and the failure is
    # therefore said once rather than restated every hour. That is the same property the
    # `📦 Release Preparation` retirement demanded, obtained by construction rather than by
    # a suppression list.
    if [ "$step" = "human-checkin" ]; then delivery_failure=1; fi
done < "${TMP}/now"

# A QUESTION IS THE ROOT'S PRECONDITION (2026-08-22, issue #569 -- the ticket's Open
# Decision, ruled here). The gates were OR: a question, OR a changed step. The root's
# stated reason to exist is that it CARRIES the tick's questions beneath it, told apart
# from them by position in the thread; with `0 question(s)` it is a status line addressed
# to nobody, which is precisely what `🔧 Needs a decision` and `📦 Release Preparation`
# were retired for -- "noise whatever its dedup key".
#
# The alternative weighed and rejected: let a NAMED CLASS of change (a merge conflict
# appearing, an auto-merge failing, a target starting to need a human) earn a
# question-less root. It is defensible, but it keeps a line nobody is asked to act on,
# needs a list maintained per step, and the developer -- shown this post twice -- said it
# was of no use to anybody. A change worth a person's attention can be asked about; one
# that cannot be is a log entry, and the tick log already keeps every one of them.
#
# THE COST, STATED RATHER THAN HIDDEN: a real change with no question attached is visible
# only in `.workaholic/moderations/`. That is the trade this ruling makes.
# THE MORNING DIGEST IS THE SECOND GATE (2026-08-24, the developer's design: the
# per-strategy standup was integrated into this tick, and the morning root is where they
# asked to find it). A tick whose `strategy-digest` step emitted a digest posts its root
# even with zero questions — once per JST day, the day's opening statement. Every other
# hour the question gate stands alone, unchanged.
digest_ready=0
grep -q '"step": *"strategy-digest".*"reason": *""' "${TMP}/now" 2>/dev/null || true
case "$INPUT" in
    *'"step": "strategy-digest"'*'render_the_morning_digest_at_the_top_of_the_root'*) digest_ready=1 ;;
esac
# A TICK THAT REACHED NOBODY IS THE THIRD GATE (2026-08-28, mission
# `deliver-what-the-loop-already-knows-to-the-person-who-can-act`), added beside the digest on
# exactly its precedent: the question gate's own expression is untouched and a second
# condition is OR'd next to it. A delivery FAILURE is the one state the root must carry with
# zero questions, because with none it says nothing at all and its silence is
# indistinguishable from a quiet hour — which is the whole defect.
#
# It is NOT the retired changed-step half of the gate. That half let ANY changed step earn a
# question-less root; this fires only when the check-in itself supplied an event, which it
# does only on a delivery failure, and only when that reading CHANGED since the previous tick
# (`delivery_failure` is set inside the diff loop). It stops entirely once the channel is
# delivering, which is what a status line addressed to nobody never did.
if [ "$QUESTIONS" -eq 0 ] && [ "$digest_ready" -eq 0 ] && [ "$delivery_failure" -eq 0 ]; then
    if [ "$count" -eq 0 ]; then
        emit false idle "" 0 "$PREV" ""
    fi
    emit false no_question "$changes" "$count" "$PREV" ""
fi

HEAD="🔎 Moderation - ${count} change(s), ${QUESTIONS} question(s)"
BODY=$(printf '%s' "$lines")
emit true ready "$changes" "$count" "$PREV" "$(printf '%s\n%s' "$HEAD" "$BODY")"
