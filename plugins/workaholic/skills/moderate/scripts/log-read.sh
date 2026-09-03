#!/bin/sh -eu
# Read the `/moderate` tick log — the answer to "did an earlier tick already do this?"
#
# WHY IT EXISTS (2026-08-17, issue #471). An hourly routine that cannot remember
# what the last twenty-three ticks did re-files the same finding every hour. The
# log is the memory, and this is the only sanctioned way a step consults it: a step
# looks for its own step id plus the identifying substring it filed under, and
# skips when it finds one. Nothing here writes; nothing here deletes.
#
# LEXICAL DATES, NO DATE ARITHMETIC. `--since` compares `YYYY-MM-DD` strings
# against the file names, which sort correctly by construction. Deliberate: `date
# -d` is GNU-only and `date -v` is BSD-only, and a reader that behaves differently
# on the developer's laptop and the routine's container is worse than one that asks
# the caller for a date.
#
# Usage:
#   log-read.sh [--since <YYYY-MM-DD>] [--tick <YYYYMMDD-HHMMSS>] [--step <slug>]
#               [--step-prefix <slug->] [--status <status>] [--contains <needle>]
#               [--root <repo-root>] [--latest-tick]
#
# `--latest-tick` ANSWERS ONE VALUE AND CARRIES NO ENTRIES (2026-09-03, mission
# `pay-only-the-operative-cost-on-every-tick`). The loop's `moderate` cadence gate needs exactly
# one thing -- how old the newest tick in the log is -- and got the whole day to supply it:
# MEASURED in one session at about 12 KB early on and **50,087 bytes two hours later**, read
# twelve times an hour and growing monotonically until the day rolls over, with nothing else in
# the tick consuming those entries. With the flag the output is
# `{"read", "latest_tick", "day", "count": 0, "entries": []}` -- the newest `(day, tick)` in the
# scanned range and an EMPTY entries array, which is honest rather than a truncation: the caller
# asked for a timestamp, not for a sample of the log.
#
# Every filter still applies, so `--step-prefix foo --latest-tick` answers *when did a `foo…` step
# last run*. `latest_tick` is the empty string when nothing matched, which a caller must read as
# *no such tick* and never as *just now*.
#
# `--step-prefix` exists because the log is idempotent per (tick, step): a step that
# records SEVERAL facts in one tick — the check-in asking up to five questions — has
# to spell each one as its own step id (`human-checkin-ask-<slug>`), and counting
# them then needs a prefix rather than an exact match.
#
# Output: one JSON line
#   {"read": true, "count": <n>, "days": <n>,
#    "entries": [{"day","tick","step","status","summary"}, ...]}
#   {"read": true, "count": 0, "days": <n>, "entries": [],
#    "latest_tick": "<YYYYMMDD-HHMMSS>", "day": "<YYYY-MM-DD>"}   (--latest-tick)
#   {"read": false, "reason": "no_log_area", "count": 0, "entries": []}
#
# `--contains` is a plain substring match over the summary, not a regex: callers
# pass an issue number or a path, and a regex metacharacter in one of those would
# silently change the question being asked.

set -eu

SINCE=''
TICK=''
STEP=''
STEP_PREFIX=''
STATUS=''
CONTAINS=''
ROOT='.'
LATEST_TICK=false

while [ $# -gt 0 ]; do
    case "$1" in
        --since)    SINCE="${2:-}"; shift 2 ;;
        --tick)     TICK="${2:-}"; shift 2 ;;
        --step)     STEP="${2:-}"; shift 2 ;;
        --step-prefix) STEP_PREFIX="${2:-}"; shift 2 ;;
        --status)   STATUS="${2:-}"; shift 2 ;;
        --contains) CONTAINS="${2:-}"; shift 2 ;;
        --root)     ROOT="${2:-}"; shift 2 ;;
        --latest-tick) LATEST_TICK=true; shift ;;
        *) echo "{\"read\": false, \"reason\": \"unknown_argument\", \"count\": 0, \"entries\": []}"; exit 1 ;;
    esac
done

DIR="$ROOT/.workaholic/moderations"
if [ ! -d "$DIR" ]; then
    echo '{"read": false, "reason": "no_log_area", "count": 0, "days": 0, "entries": []}'
    exit 0
fi

days=0
entries=''
for file in "$DIR"/*.md; do
    [ -f "$file" ] || continue
    day=$(basename "$file" .md)
    case "$day" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
        *) continue ;;
    esac
    # Lexical: the file names are fixed-width dates.
    if [ -n "$SINCE" ] && [ "$day" \< "$SINCE" ]; then
        continue
    fi
    days=$((days + 1))
    rows=$(awk -v day="$day" -v want_tick="$TICK" -v want_step="$STEP" \
               -v want_prefix="$STEP_PREFIX" -v want_status="$STATUS" -v needle="$CONTAINS" '
        function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }
        substr($0, 1, 3) == "## " { tick = substr($0, 4); sub(/[ \t]+$/, "", tick); next }
        substr($0, 1, 3) != "- `" { next }
        {
            rest = substr($0, 4)
            close_tick = index(rest, "`: ")
            if (close_tick == 0) next
            step = substr(rest, 1, close_tick - 1)
            rest = substr(rest, close_tick + 3)
            sep = index(rest, " — ")
            if (sep == 0) next
            status = substr(rest, 1, sep - 1)
            summary = substr(rest, sep + length(" — "))

            if (want_tick != "" && tick != want_tick) next
            if (want_step != "" && step != want_step) next
            if (want_prefix != "" && substr(step, 1, length(want_prefix)) != want_prefix) next
            if (want_status != "" && status != want_status) next
            if (needle != "" && index(summary, needle) == 0) next

            printf "%s{\"day\": \"%s\", \"tick\": \"%s\", \"step\": \"%s\", \"status\": \"%s\", \"summary\": \"%s\"}",
                (n++ ? ", " : ""), esc(day), esc(tick), esc(step), esc(status), esc(summary)
        }
    ' "$file")
    [ -n "$rows" ] || continue
    if [ -n "$entries" ]; then
        entries="$entries, $rows"
    else
        entries="$rows"
    fi
done

count=$(printf '%s' "$entries" | awk '{ n = gsub(/\{"day":/, "&"); total += n } END { print total + 0 }')

if [ "$LATEST_TICK" = "true" ]; then
    # The newest `(day, tick)` among the rows the filters kept, and NOTHING ELSE. The rows were
    # built anyway -- the saving is entirely in what crosses the boundary to the caller, which is
    # where the 50 KB was being paid.
    latest=$(printf '%s' "$entries" | tr ',' '\n' \
        | sed -n 's/.*"tick": "\([^"]*\)".*/\1/p' | LC_ALL=C sort | tail -1)
    latest_day=$(printf '%s' "$entries" | tr '}' '\n' \
        | grep -F "\"tick\": \"${latest}\"" 2>/dev/null \
        | sed -n 's/.*"day": "\([^"]*\)".*/\1/p' | LC_ALL=C sort | tail -1)
    printf '{"read": true, "count": 0, "days": %s, "entries": [], "latest_tick": "%s", "day": "%s"}\n' \
        "$days" "${latest:-}" "${latest_day:-}"
    exit 0
fi

printf '{"read": true, "count": %s, "days": %s, "entries": [%s]}\n' "$count" "$days" "$entries"
