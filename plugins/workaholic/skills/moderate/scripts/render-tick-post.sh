#!/bin/sh -eu
# render-tick-post.sh — THE TICK'S OWN VOICE: what changed in this hour, and whether
# that is worth a person's attention at all.
#
# Usage: run.sh ... | render-tick-post.sh --tick <id> [--root <repo-root>] [--questions <n>]
# Output: one JSON object
#   {"post": bool, "reason": "...", "tick": "...", "token": "tick:<id>",
#    "changes": [{"step","summary"}], "change_count": N, "questions": N,
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
#   post: true   at least one question to ask, OR at least one changed step
#   post: false  reasons: `idle` (nothing changed, nothing to ask), `no_previous_tick`,
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

changes=''
count=0
lines=''
TAB=$(printf '\t')
while IFS="$TAB" read -r step summary || [ -n "$step" ]; do
    [ -n "$step" ] || continue
    # The check-in is the tick's asking step; its own summary changing is not news about
    # the repository, and its questions are already the thread's replies.
    [ "$step" = "human-checkin" ] && continue
    [ "$step" = "open-log" ] && continue
    was=$(awk -F"$TAB" -v s="$step" '$1 == s { print $2; exit }' "${TMP}/prev")
    [ "$was" = "$summary" ] && continue
    changes="${changes:+${changes}, }{\"step\": \"$(json_escape "$step")\", \"summary\": \"$(json_escape "$summary")\"}"
    lines="${lines}${step}: ${summary}
"
    count=$((count + 1))
done < "${TMP}/now"

if [ "$count" -eq 0 ] && [ "$QUESTIONS" -eq 0 ]; then
    emit false idle "" 0 "$PREV" ""
fi

HEAD="🔎 Moderation - ${count} change(s), ${QUESTIONS} question(s)"
BODY=$(printf '%s' "$lines")
emit true ready "$changes" "$count" "$PREV" "$(printf '%s\n%s' "$HEAD" "$BODY")"
