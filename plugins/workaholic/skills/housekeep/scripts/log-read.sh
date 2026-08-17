#!/bin/sh -eu
# Read the `/housekeep` tick log — the answer to "did an earlier tick already do this?"
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
#               [--status <status>] [--contains <needle>] [--root <repo-root>]
#
# Output: one JSON line
#   {"read": true, "count": <n>, "days": <n>,
#    "entries": [{"day","tick","step","status","summary"}, ...]}
#   {"read": false, "reason": "no_log_area", "count": 0, "entries": []}
#
# `--contains` is a plain substring match over the summary, not a regex: callers
# pass an issue number or a path, and a regex metacharacter in one of those would
# silently change the question being asked.

set -eu

SINCE=''
TICK=''
STEP=''
STATUS=''
CONTAINS=''
ROOT='.'

while [ $# -gt 0 ]; do
    case "$1" in
        --since)    SINCE="${2:-}"; shift 2 ;;
        --tick)     TICK="${2:-}"; shift 2 ;;
        --step)     STEP="${2:-}"; shift 2 ;;
        --status)   STATUS="${2:-}"; shift 2 ;;
        --contains) CONTAINS="${2:-}"; shift 2 ;;
        --root)     ROOT="${2:-}"; shift 2 ;;
        *) echo "{\"read\": false, \"reason\": \"unknown_argument\", \"count\": 0, \"entries\": []}"; exit 1 ;;
    esac
done

DIR="$ROOT/.workaholic/housekeeping"
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
               -v want_status="$STATUS" -v needle="$CONTAINS" '
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

printf '{"read": true, "count": %s, "days": %s, "entries": [%s]}\n' "$count" "$days" "$entries"
