#!/bin/sh -eu
# The gate one check-in question must pass before a human's attention is spent.
#
# WHY A SCRIPT DECIDES AND THE AGENT COMPOSES. Whether something is worth asking is
# a judgement (`rules/interaction.md`'s Recommended-label test: if an option could
# honestly be marked "(Recommended)", do not ask — decide, record, let the
# developer veto). Whether it may be asked *now*, *again*, or *at all this tick* is
# mechanical, and mechanical is what a five-questions-an-hour ceiling needs, because
# a model asked to police its own volume will do it inconsistently.
#
# FOUR GATES, EACH ITS OWN REFUSAL:
#   quiet_hours   inside the configured window; the question is HELD, never dropped
#   already_asked this exact question key was asked in an earlier tick
#   tick_cap      five per tick, the ask's own ceiling
#   day_cap       the bound the per-tick cap must not aggregate past (default 10)
#
# QUIET HOURS ARE ONE GATE PER TICK, IN THE WORKSPACE'S TIMEZONE (resolved
# 2026-08-17, the ticket's first Open Decision). Default `Asia/Tokyo`, 22:00–08:00,
# both overridable — `WORKAHOLIC_QUIET_TZ`, `WORKAHOLIC_QUIET_HOURS=<start>-<end>`.
# The per-recipient alternative (each addressee's Slack profile timezone) is more
# precise and was not taken: it costs a profile read per person per tick against a
# surface this project keeps to exact-string queries, and it buys little, because a
# suppressed question is HELD rather than dropped — the cost of a coarse gate is a
# few hours of delay, not a lost question. The gate stays swappable: it is one
# function reading one zone.
#
# SILENCE IS NOT CONSENT, AND IT IS NOT A REASON TO ASK AGAIN (resolved 2026-08-17,
# the second Open Decision). An unanswered question is never re-posted: the
# red-alert `↳ still failing` precedent covers a machine-observable state that
# persists, whereas a question is a demand on a person's attention, and repeating it
# hourly converts asking into nagging. The unanswered set stays visible where humans
# already look — the tick log and the run report — and the post itself is still
# sitting in its thread.
#
# Usage:
#   ask-question.sh --tick <id> --key <content-key> [--root <repo-root>]
#                   [--to <email>] [--hour <0-23>] [--weekday <1-7>]
#                   [--max-per-tick 5] [--max-per-day 10]
#
# Output: one JSON line
#   {"ask": true, "key": "...", "log_step": "human-checkin-ask-<slug>",
#    "mention_email": "...", "asked_this_tick": n, "asked_today": n}
#   {"ask": false, "reason": "off_day|quiet_hours|already_asked|tick_cap|day_cap|no_key",
#    "hold": true|false, "window": "22-08 Asia/Tokyo", ...}
#
# `mention_email` is what the CALLER resolves to a `<@U…>` mention: a bare `@name`
# pings nobody, and a Claude mention token on a routine's own post re-triggers the
# app and is prohibited (`workaholic:notify`).

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
LOG_READ="${SCRIPT_DIR}/log-read.sh"

TICK=''
KEY=''
ROOT='.'
TO=''
HOUR=''
WEEKDAY=''
MAX_TICK=5
MAX_DAY=10

while [ $# -gt 0 ]; do
    case "$1" in
        --tick)         TICK="${2:-}"; shift 2 ;;
        --key)          KEY="${2:-}"; shift 2 ;;
        --root)         ROOT="${2:-}"; shift 2 ;;
        --to)           TO="${2:-}"; shift 2 ;;
        --hour)         HOUR="${2:-}"; shift 2 ;;
        --weekday)      WEEKDAY="${2:-}"; shift 2 ;;
        --max-per-tick) MAX_TICK="${2:-5}"; shift 2 ;;
        --max-per-day)  MAX_DAY="${2:-10}"; shift 2 ;;
        *) shift ;;
    esac
done

[ -n "$KEY" ] || { echo '{"ask": false, "reason": "no_key", "hold": false}'; exit 1; }

# WORKING TIME IS A DAY AND AN HOUR, NOT AN HOUR ALONE (2026-08-21, the developer's
# instruction). The gate only ever checked the clock, so a question found at 10:00 on a
# Sunday was posted into a channel nobody was reading, and its `already_asked` gate then
# ensured it was never posted again on a day somebody was. Held is not dropped, so a
# weekend finding waits for Monday and is asked then. `WORKAHOLIC_WORK_DAYS` is a
# `%u` range (1 = Monday), so `1-5` is the working week and `1-7` opts the gate out.
ZONE="${WORKAHOLIC_QUIET_TZ:-Asia/Tokyo}"
WINDOW="${WORKAHOLIC_QUIET_HOURS:-22-08}"
WORK_DAYS="${WORKAHOLIC_WORK_DAYS:-1-5}"
START=$(printf '%s' "$WINDOW" | cut -d- -f1)
END=$(printf '%s' "$WINDOW" | cut -d- -f2)

if [ -z "$HOUR" ]; then
    HOUR=$(TZ="$ZONE" date +%H)
fi
HOUR=$(printf '%s' "$HOUR" | sed 's/^0//')
[ -n "$HOUR" ] || HOUR=0

DAY_START=$(printf '%s' "$WORK_DAYS" | cut -d- -f1)
DAY_END=$(printf '%s' "$WORK_DAYS" | cut -d- -f2)
if [ -z "$WEEKDAY" ]; then
    WEEKDAY=$(TZ="$ZONE" date +%u)
fi
case "$WEEKDAY" in ''|*[!0-9]*) WEEKDAY=1 ;; esac

offday=false
if [ "$WEEKDAY" -lt "$DAY_START" ] || [ "$WEEKDAY" -gt "$DAY_END" ]; then offday=true; fi

quiet=false
if [ "$START" -gt "$END" ]; then
    # The window crosses midnight, which is the normal case for "late night".
    if [ "$HOUR" -ge "$START" ] || [ "$HOUR" -lt "$END" ]; then quiet=true; fi
else
    if [ "$HOUR" -ge "$START" ] && [ "$HOUR" -lt "$END" ]; then quiet=true; fi
fi

count_log_prefix() {
    # $1 step-id prefix, $2 needle ("" for all) -> count, 0 when the log is unreadable
    if [ ! -f "$LOG_READ" ]; then printf '0'; return 0; fi
    if [ -n "$2" ]; then
        out=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "$1" --contains "$2" 2>/dev/null || true)
    else
        out=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "$1" 2>/dev/null || true)
    fi
    n=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    printf '%s' "$n"
}

count_log_step() {
    # $1 exact step id -> count, 0 when the log is unreadable
    if [ ! -f "$LOG_READ" ]; then printf '0'; return 0; fi
    out=$(sh "$LOG_READ" --root "$ROOT" --step "$1" 2>/dev/null || true)
    n=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    printf '%s' "$n"
}

# One step id per question, because the log is idempotent per (tick, step): five
# questions in a tick are five ids, and the count is a prefix query.
#
# THE ID IS INJECTIVE ON THE KEY, which the slug alone was not: it lowercases, collapses
# every non-alphanumeric run and truncates to 32 characters, so two long keys sharing a
# prefix produced one id — and once the gate reads the id (above), a collision silently
# SUPPRESSES a question rather than merely miscounting one. A short digest of the whole
# key is appended so that cannot happen. The ids therefore changed shape on 2026-08-21:
# a question asked under the old id is asked once more, which is the one-off cost of
# making the gate mechanical.
SLUG=$(printf '%s' "$KEY" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9]\{1,\}/-/g; s/^-//; s/-$//' | cut -c1-24)
[ -n "$SLUG" ] || SLUG=q
DIGEST=$(printf '%s' "$KEY" | cksum | cut -d' ' -f1)
LOG_STEP="human-checkin-ask-${SLUG}-${DIGEST}"

# THE GATE MATCHES THE STEP ID, NEVER THE SUMMARY TEXT (2026-08-21, ticket
# `20260819062058`). It used to ask the log for a line whose SUMMARY contained the raw
# key — but nothing ever required the writer to put the key in the summary, and the log's
# own identity for a question is the step id derived here. So the gate depended on an
# agent having written free text a contract never asked for, and measurably did not hold:
# tick `20260819-045108` asked `ask:issue-524-unassigned-never-ingested`, and an hour
# later the same key answered `{"ask": true}` with the question still unanswered in the
# channel. Reading the id makes the gate mechanical, which is what a ceiling needs.
already=$(count_log_step "$LOG_STEP")
if [ "$already" != "0" ]; then
    printf '{"ask": false, "reason": "already_asked", "hold": false, "key": "%s"}\n' "$KEY"
    exit 0
fi

asked_today=$(count_log_prefix human-checkin-ask "")
asked_tick=0
if [ -f "$LOG_READ" ]; then
    out=$(sh "$LOG_READ" --root "$ROOT" --step-prefix human-checkin-ask --tick "$TICK" 2>/dev/null || true)
    asked_tick=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')
    case "$asked_tick" in ''|*[!0-9]*) asked_tick=0 ;; esac
fi

if [ "$offday" = "true" ]; then
    printf '{"ask": false, "reason": "off_day", "hold": true, "key": "%s", "work_days": "%s", "weekday": %s, "tz": "%s"}\n' \
        "$KEY" "$WORK_DAYS" "$WEEKDAY" "$ZONE"
    exit 0
fi

if [ "$quiet" = "true" ]; then
    printf '{"ask": false, "reason": "quiet_hours", "hold": true, "key": "%s", "window": "%s %s", "hour": %s}\n' \
        "$KEY" "$WINDOW" "$ZONE" "$HOUR"
    exit 0
fi

if [ "$asked_tick" -ge "$MAX_TICK" ]; then
    printf '{"ask": false, "reason": "tick_cap", "hold": true, "key": "%s", "asked_this_tick": %s, "max_per_tick": %s}\n' \
        "$KEY" "$asked_tick" "$MAX_TICK"
    exit 0
fi

if [ "$asked_today" -ge "$MAX_DAY" ]; then
    printf '{"ask": false, "reason": "day_cap", "hold": true, "key": "%s", "asked_today": %s, "max_per_day": %s}\n' \
        "$KEY" "$asked_today" "$MAX_DAY"
    exit 0
fi

printf '{"ask": true, "key": "%s", "log_step": "%s", "mention_email": "%s", "asked_this_tick": %s, "asked_today": %s, "window": "%s %s"}\n' \
    "$KEY" "$LOG_STEP" "$TO" "$asked_tick" "$asked_today" "$WINDOW" "$ZONE"
