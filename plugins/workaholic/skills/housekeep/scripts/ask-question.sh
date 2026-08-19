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
#   already_asked this exact question key was asked in an earlier tick — decided by an
#                 EXACT step-id match, never by a substring search over the agent's
#                 own log wording (2026-08-19; see the gate below for what that cost)
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
#                   [--to <email>] [--hour <0-23>] [--max-per-tick 5] [--max-per-day 10]
#
# Output: one JSON line
#   {"ask": true, "key": "...", "log_step": "human-checkin-ask-<slug>",
#    "mention_email": "...", "asked_this_tick": n, "asked_today": n}
#   {"ask": false, "reason": "quiet_hours|already_asked|tick_cap|day_cap|no_key",
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
MAX_TICK=5
MAX_DAY=10

while [ $# -gt 0 ]; do
    case "$1" in
        --tick)         TICK="${2:-}"; shift 2 ;;
        --key)          KEY="${2:-}"; shift 2 ;;
        --root)         ROOT="${2:-}"; shift 2 ;;
        --to)           TO="${2:-}"; shift 2 ;;
        --hour)         HOUR="${2:-}"; shift 2 ;;
        --max-per-tick) MAX_TICK="${2:-5}"; shift 2 ;;
        --max-per-day)  MAX_DAY="${2:-10}"; shift 2 ;;
        *) shift ;;
    esac
done

[ -n "$KEY" ] || { echo '{"ask": false, "reason": "no_key", "hold": false}'; exit 1; }

ZONE="${WORKAHOLIC_QUIET_TZ:-Asia/Tokyo}"
WINDOW="${WORKAHOLIC_QUIET_HOURS:-22-08}"
START=$(printf '%s' "$WINDOW" | cut -d- -f1)
END=$(printf '%s' "$WINDOW" | cut -d- -f2)

if [ -z "$HOUR" ]; then
    HOUR=$(TZ="$ZONE" date +%H)
fi
HOUR=$(printf '%s' "$HOUR" | sed 's/^0//')
[ -n "$HOUR" ] || HOUR=0

quiet=false
if [ "$START" -gt "$END" ]; then
    # The window crosses midnight, which is the normal case for "late night".
    if [ "$HOUR" -ge "$START" ] || [ "$HOUR" -lt "$END" ]; then quiet=true; fi
else
    if [ "$HOUR" -ge "$START" ] && [ "$HOUR" -lt "$END" ]; then quiet=true; fi
fi

count_log_prefix() {
    # $1 step-id prefix -> count of entries under it, 0 when the log is unreadable.
    # Used for the VOLUME gates only (tick_cap, day_cap), where every question counts
    # and no identity is being asserted.
    if [ ! -f "$LOG_READ" ]; then printf '0'; return 0; fi
    out=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "$1" 2>/dev/null || true)
    n=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    printf '%s' "$n"
}

count_log_step() {
    # $1 EXACT step id -> count, 0 when the log is unreadable. `--step` is an
    # identity match against the step id, which is what the already-asked gate needs.
    if [ ! -f "$LOG_READ" ]; then printf '0'; return 0; fi
    out=$(sh "$LOG_READ" --root "$ROOT" --step "$1" 2>/dev/null || true)
    n=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    printf '%s' "$n"
}

# One step id per question, because the log is idempotent per (tick, step): five
# questions in a tick are five ids, and the volume count is a prefix query.
#
# THE ID IS AN IDENTITY, AND A LONG KEY KEEPS ITS OWN (2026-08-19, issue #524's
# report). The id was `cut -c1-32` of the slug, which cost two things measured
# together: a key longer than that produced an id that did not contain its own key,
# and two keys sharing a 32-character prefix produced the SAME id. A truncated slug
# is kept for readability and a `cksum` of the FULL key is appended whenever the
# truncation actually happened, so distinct keys keep distinct ids and a short key's
# id does not move at all.
FULL_SLUG=$(printf '%s' "$KEY" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9]\{1,\}/-/g; s/^-//; s/-$//')
[ -n "$FULL_SLUG" ] || FULL_SLUG=q
LEGACY_SLUG=$(printf '%s' "$FULL_SLUG" | cut -c1-32)
if [ "${#FULL_SLUG}" -gt 32 ]; then
    SLUG="$(printf '%s' "$FULL_SLUG" | cut -c1-22)-$(printf '%s' "$KEY" | cksum | awk '{ print $1 }')"
else
    SLUG="$FULL_SLUG"
fi
LOG_STEP="human-checkin-ask-${SLUG}"

# THE GATE IS AN IDENTITY, NOT A SEARCH OVER PROSE. It read
# `--step-prefix human-checkin-ask --contains "$KEY"`, and `--contains` matches the
# SUMMARY — agent-composed text — so whether a question counted as already asked was
# a property of how the last tick happened to word its log line. Measured: tick
# `20260819-045108` asked `ask:issue-524-unassigned-never-ingested` and an hour later
# the same key answered `ask: true` while the question still sat unanswered in Slack.
# Both sides now derive the step id from the key through the code path above — the
# caller records under the `log_step` this script returns — so the match is an
# identity and no wording can change it.
already=$(count_log_step "$LOG_STEP")
# A BOUNDED LEGACY TOLERANCE, written to be deleted. Entries written before the id
# gained its digest sit under the plain 32-character truncation, so without this a
# long-key question already asked would be asked exactly once more — the very case
# the report measured. It reintroduces the prefix collision for those entries only,
# which is strictly smaller than the collision that existed everywhere before, and
# it decays as the log ages: drop this branch once no live log carries a truncated
# id.
if [ "$already" = "0" ] && [ "$SLUG" != "$LEGACY_SLUG" ]; then
    already=$(count_log_step "human-checkin-ask-${LEGACY_SLUG}")
fi
if [ "$already" != "0" ]; then
    printf '{"ask": false, "reason": "already_asked", "hold": false, "key": "%s", "log_step": "%s"}\n' \
        "$KEY" "$LOG_STEP"
    exit 0
fi

asked_today=$(count_log_prefix human-checkin-ask)
asked_tick=0
if [ -f "$LOG_READ" ]; then
    out=$(sh "$LOG_READ" --root "$ROOT" --step-prefix human-checkin-ask --tick "$TICK" 2>/dev/null || true)
    asked_tick=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')
    case "$asked_tick" in ''|*[!0-9]*) asked_tick=0 ;; esac
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
