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
#               [--owner <moderate|loop|propose|all>]
#               [--root <repo-root>] [--latest-tick]
#
# `--owner` IS THE SECTION'S OWNER, DERIVED FROM THE STEP ID, AND IT DEFAULTS TO
# `moderate` (2026-09-07, ticket `20260907063154`). THE DEFAULT IS THE WHOLE POINT:
# *a caller that names no owner is asking about moderation.*
#
# WHY. Three producers write into this one file under their OWN tick ids.
# `/moderate` writes its steps; `/infinite-development` records each subagent finish as
# `loop-finish-<name>` under the COORDINATOR's tick id; `/propose` writes `propose-open`
# and `propose-close`. The coordinator turns every five minutes and `/moderate` every
# thirty, so a section holding nothing but a `loop-finish-*` line is the ORDINARY previous
# section, not an edge case — MEASURED on `.workaholic/moderations/2026-09-06.md`: 84
# `loop-finish-*` lines, 0 `human-checkin-post` lines, and sections `20260906-204212` and
# `20260906-210558` each holding exactly one `loop-finish-*` line and nothing else.
#
# Two readers were already broken by the mixing, both SILENTLY:
#   * `render-tick-post.sh`'s change baseline fell back to the newest tick before this one
#     WHATEVER step it carried, landed on a coordinator section, read an empty `prev`, and
#     counted every eventful step as changed — the diff no longer suppressing an unchanged
#     answer, which is the one property it exists to guarantee.
#   * `step-blocked-tick.sh` took a coordinator section as "the tick before last", found
#     `opened == 0`, and reported `the tick before last opened and closed` — the step whose
#     whole job is to notice a stopped tick reporting a FALSE HEALTHY reading.
# Repairing the READER repairs both without touching either, and every future reader
# inherits the repair instead of the trap.
#
# THE TABLE IS CLOSED, NAMED, AND DERIVED FROM THE STEP ID EVERY LINE ALREADY CARRIES —
# no new field, no new file, no stored value, no migration, and the lines already on disk
# are classified by construction:
#   `loop-finish-*`, `loop-attempt-*` -> `loop`     (the coordinator's own finish records)
#   `propose-*`                       -> `propose`  (`/propose`'s opening and closing lines)
#   everything else                   -> `moderate` (the existing behaviour)
# An UNRECOGNISED step id is `moderate`, so nothing already written moves. The
# classification is PER ENTRY, never per section: a section that ever mixes two owners
# degrades to the right answer per line rather than to a guess about the section.
#
# It composes with every other filter exactly as `--step-prefix` does, `--latest-tick`
# included, so `--owner loop --step-prefix loop-finish-implement --latest-tick` answers
# *when did the implement runner last finish*. `--owner all` is the pre-2026-09-07
# behaviour, for a caller that genuinely wants the whole file.
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
OWNER='moderate'

while [ $# -gt 0 ]; do
    case "$1" in
        --since)    SINCE="${2:-}"; shift 2 ;;
        --tick)     TICK="${2:-}"; shift 2 ;;
        --step)     STEP="${2:-}"; shift 2 ;;
        --step-prefix) STEP_PREFIX="${2:-}"; shift 2 ;;
        --status)   STATUS="${2:-}"; shift 2 ;;
        --contains) CONTAINS="${2:-}"; shift 2 ;;
        --owner)    OWNER="${2:-}"; shift 2 ;;
        --root)     ROOT="${2:-}"; shift 2 ;;
        --latest-tick) LATEST_TICK=true; shift ;;
        *) echo "{\"read\": false, \"reason\": \"unknown_argument\", \"count\": 0, \"entries\": []}"; exit 1 ;;
    esac
done

# An owner outside the closed set is the CALLER's defect, not a data problem, so it is
# refused by name rather than silently widened to `all` or narrowed to `moderate`.
case "$OWNER" in
    moderate|loop|propose|all) ;;
    *) echo "{\"read\": false, \"reason\": \"bad_owner\", \"count\": 0, \"days\": 0, \"entries\": []}"; exit 1 ;;
esac

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
               -v want_prefix="$STEP_PREFIX" -v want_status="$STATUS" -v needle="$CONTAINS" \
               -v want_owner="$OWNER" '
        function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }
        # THE OWNER TABLE, and the only copy of it. Prefix tests in the order the header
        # states; an unrecognised step id falls through to `moderate`, which is what every
        # line meant before this existed.
        function owner_of(s) {
            if (substr(s, 1, 12) == "loop-finish-") return "loop"
            if (substr(s, 1, 13) == "loop-attempt-") return "loop"
            if (substr(s, 1, 8)  == "propose-") return "propose"
            return "moderate"
        }
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

            if (want_owner != "all" && owner_of(step) != want_owner) next
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
