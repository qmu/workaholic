#!/bin/sh -eu
# Read the `/moderate` tick log — the answer to "did an earlier tick already do this?"
#
# WHY IT EXISTS (2026-08-17, issue #471). An hourly routine that cannot remember
# what the last twenty-three ticks did re-files the same finding every hour. The
# log is the memory, and this is the only sanctioned way a step consults it: a step
# looks for its own step id plus the identifying substring it filed under, and
# skips when it finds one. Nothing here writes to the log; nothing here deletes.
#
# IT IS ALSO THE ONE RESOLVER OF THE LOG'S LOCATION (2026-08-31, mission
# `take-the-moderation-tick-s-log-off-main`). The log now lives on its own ref rather than on
# the base (`workaholic:moderate`, *Where the log lives, and why it is not `main`*), which
# means "where is the log" stopped being a constant. Six scripts composed
# `.workaholic/moderations` for themselves; after the move each of them would have walked an
# empty directory and reported *nothing found* rather than *could not read* — and every dedup
# in the tick would re-fire, which is the one failure the log exists to prevent. So the
# location resolves HERE and nowhere else. `log-append.sh` keeps writing the checkout copy,
# which is legitimate and stays; `persist-log.sh` publishes it. Every reader composes this.
#
# TWO SOURCES, AND THE PRECEDENCE IS STATED RATHER THAN LEFT TO BE INFERRED:
#
#   1. THE REF'S COPY, materialized into a cache under the git directory by `--refresh`.
#      This is every earlier tick's log, including ticks from containers long discarded.
#   2. THE CHECKOUT'S COPY (`.workaholic/moderations/`), which is what THIS container has
#      appended so far through `log-append.sh` — including lines written seconds ago and not
#      yet published.
#
# THE CHECKOUT WINS on a `(tick, step)` collision. Two reasons, and the second is the one
# that matters: a line this container just wrote is by construction newer than anything the
# ref carries for the same key; and a step that read a stale ref copy while the checkout held
# a newer line would re-file what it had already filed. Presence is what every dedup actually
# asks, and both sources contribute presence, so the precedence only ever decides which
# rendering of one line a caller sees — never whether the line is seen at all.
#
# THE CACHE LIVES UNDER THE GIT DIRECTORY, NOT IN THE WORKING TREE. It is therefore never
# staged, never in `git status`, never picked up by a `git add .`, and needs no `.gitignore`
# entry in any repository that installs this plugin — which matters, because a plugin cannot
# ship a `.gitignore` change to a consuming repository. A working-tree cache would have been
# one `git add -A` away from putting the whole log back on `main`.
#
# A REFRESH THAT COULD NOT REACH THE REF IS NAMED, NEVER RENDERED AS AN EMPTY LOG. The state
# of the last refresh is recorded beside the cache and read back here: `log_ref_unreachable`
# answers `read: false` with a NULL count. `no_log_area` keeps meaning what it always meant —
# there is no log — and the two must never collapse, because "could not look" read as
# "nothing was filed" makes every dedup in the tick re-fire.
#
# A CHECKOUT THAT NEVER REFRESHED READS EXACTLY AS IT DID BEFORE THIS EXISTED: no state file
# means no ref was ever consulted, so the checkout's own copy is the whole answer and
# `read: true`. That is what keeps a hand-run, and every hermetic fixture, unchanged.
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
#               [--root <repo-root>] [--refresh] [--list-days] [--log-dir]
#
# `--step-prefix` exists because the log is idempotent per (tick, step): a step that
# records SEVERAL facts in one tick — the check-in asking up to five questions — has
# to spell each one as its own step id (`human-checkin-ask-<slug>`), and counting
# them then needs a prefix rather than an exact match.
#
# `--refresh` fetches the log ref and materializes it. It is run ONCE per tick, by the
# `open-log` step, and by nothing else: a reader that fetched would put a network call behind
# every dedup in the tick.
#
# `--list-days` answers the union of day names, newest last — the listing `condition-age.sh`
# and `step-blocked-tick.sh` used to derive by walking the directory themselves.
#
# `--log-dir` answers where the CHECKOUT's copy lives — the one path `log-append.sh`,
# `step-open-log.sh` and `run.sh` need, resolved here so they compose no path of their own.
#
# Output: one JSON line
#   {"read": true, "count": <n>, "days": <n>,
#    "entries": [{"day","tick","step","status","summary"}, ...]}
#   {"read": false, "reason": "no_log_area", "count": 0, "entries": []}
#   {"read": false, "reason": "log_ref_unreachable", "count": null, "days": null, "entries": []}
#
# `--contains` is a plain substring match over the summary, not a regex: callers
# pass an issue number or a path, and a regex metacharacter in one of those would
# silently change the question being asked.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/log-ref.sh"

SINCE=''
TICK=''
STEP=''
STEP_PREFIX=''
STATUS=''
CONTAINS=''
ROOT='.'
REFRESH=0
MODE=entries

while [ $# -gt 0 ]; do
    case "$1" in
        --since)    SINCE="${2:-}"; shift 2 ;;
        --tick)     TICK="${2:-}"; shift 2 ;;
        --step)     STEP="${2:-}"; shift 2 ;;
        --step-prefix) STEP_PREFIX="${2:-}"; shift 2 ;;
        --status)   STATUS="${2:-}"; shift 2 ;;
        --contains) CONTAINS="${2:-}"; shift 2 ;;
        --root)     ROOT="${2:-}"; shift 2 ;;
        --refresh)  REFRESH=1; shift ;;
        --list-days) MODE=days; shift ;;
        --log-dir)  MODE=logdir; shift ;;
        *) echo "{\"read\": false, \"reason\": \"unknown_argument\", \"count\": 0, \"entries\": []}"; exit 1 ;;
    esac
done

# THE CHECKOUT'S COPY. This is the one path resolved for every caller.
DIR="$ROOT/${WORKAHOLIC_LOG_DIR_REL}"

if [ "$MODE" = logdir ]; then
    printf '{"read": true, "log_dir": "%s", "present": %s}\n' \
        "$DIR" "$( [ -d "$DIR" ] && printf true || printf false )"
    exit 0
fi

# THE REF'S COPY, cached under the git directory — outside the working tree, so it is never
# staged and never reaches `main` by accident.
CACHE=''
CACHE_DIR=''
STATE_FILE=''
git_dir=$(git -C "$ROOT" rev-parse --absolute-git-dir 2>/dev/null || printf '')
if [ -n "$git_dir" ]; then
    CACHE="${git_dir}/workaholic/moderation-log"
    CACHE_DIR="${CACHE}/${WORKAHOLIC_LOG_DIR_REL}"
    STATE_FILE="${CACHE}/.state"
fi

if [ "$REFRESH" = 1 ] && [ -n "$CACHE" ]; then
    state=$(workaholic_log_fetch "$ROOT")
    mkdir -p "$CACHE" 2>/dev/null || true
    if [ "$state" = ok ]; then
        # ONE CALL, NOT ONE PER DAY FILE. `checkout-index` writes the whole tree the ref
        # carries — which is the day files and nothing else — against a scratch index, so
        # the caller's index and working tree are untouched.
        rm -rf "$CACHE_DIR" 2>/dev/null || true
        mkdir -p "$CACHE" 2>/dev/null || true
        idx="${CACHE}/.index"
        rm -f "$idx" 2>/dev/null || true
        if GIT_INDEX_FILE="$idx" git -C "$ROOT" read-tree "$WORKAHOLIC_LOG_REMOTE_REF" 2>/dev/null \
            && GIT_INDEX_FILE="$idx" git -C "$ROOT" --work-tree="$CACHE" checkout-index -a -f 2>/dev/null; then
            printf 'ok' > "$STATE_FILE" 2>/dev/null || true
        else
            printf 'unreachable' > "$STATE_FILE" 2>/dev/null || true
        fi
        rm -f "$idx" 2>/dev/null || true
    else
        # `absent` and `no_origin` are not degradations: the first is a repository whose
        # first tick has not published yet, the second a local-only checkout. Neither is
        # `unreachable`, and rendering either as one would send somebody after a fetch that
        # is working exactly as it should.
        printf '%s' "$state" > "$STATE_FILE" 2>/dev/null || true
    fi
fi

REF_STATE=''
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
    REF_STATE=$(cat "$STATE_FILE" 2>/dev/null || printf '')
fi

if [ "$REF_STATE" = unreachable ]; then
    # A NULL COUNT, NEVER A ZERO. A zero is an answer; this is the absence of one.
    echo '{"read": false, "reason": "log_ref_unreachable", "count": null, "days": null, "entries": []}'
    exit 0
fi

have_checkout=false
[ -d "$DIR" ] && have_checkout=true
have_cache=false
[ -n "$CACHE_DIR" ] && [ -d "$CACHE_DIR" ] && have_cache=true

if [ "$have_checkout" = false ] && [ "$have_cache" = false ]; then
    if [ "$MODE" = days ]; then
        echo '{"read": false, "reason": "no_log_area", "days": [], "count": 0}'
    else
        echo '{"read": false, "reason": "no_log_area", "count": 0, "days": 0, "entries": []}'
    fi
    exit 0
fi

day_name_list() {
    { [ "$have_checkout" = true ] && ls -1 "$DIR" 2>/dev/null || true
      [ "$have_cache" = true ] && ls -1 "$CACHE_DIR" 2>/dev/null || true
    } | sed -n 's/^\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)\.md$/\1/p' | sort -u
}

all_days=$(day_name_list)

if [ "$MODE" = days ]; then
    rows=''
    for day in $all_days; do
        if [ -n "$SINCE" ] && [ "$day" \< "$SINCE" ]; then continue; fi
        if [ -n "$rows" ]; then rows="$rows, \"$day\""; else rows="\"$day\""; fi
    done
    n=$(printf '%s' "$all_days" | grep -c . 2>/dev/null || printf 0)
    printf '{"read": true, "days": [%s], "count": %s}\n' "$rows" "$n"
    exit 0
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

days=0
entries=''
for day in $all_days; do
    # Lexical: the file names are fixed-width dates.
    if [ -n "$SINCE" ] && [ "$day" \< "$SINCE" ]; then
        continue
    fi
    local_file="${DIR}/${day}.md"
    cache_file="${CACHE_DIR}/${day}.md"
    file="$WORK/day.md"

    if [ -s "$local_file" ] && [ -s "$cache_file" ]; then
        # BOTH SOURCES CARRY THIS DAY: union by `(tick, step)`, the CHECKOUT winning. The
        # checkout's copy is taken whole and the ref contributes only what it lacks — whole
        # sections first, then individual entries inside a section they share.
        cp "$local_file" "$file"
        for t in $(grep '^## ' "$cache_file" | sed 's/^## //' || true); do
            if ! grep -q "^## ${t}\$" "$file"; then
                section=$(awk -v head="## $t" '
                    $0 == head { inside = 1; print; next }
                    inside && substr($0, 1, 3) == "## " { exit }
                    inside { print }
                ' "$cache_file" | awk '{ lines[NR] = $0 } END { last = NR; while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--; for (i = 1; i <= last; i++) print lines[i] }')
                [ -n "$section" ] || continue
                printf '\n%s\n' "$section" >> "$file"
                continue
            fi
            awk -v head="## $t" '
                function key(line,   rest, i) {
                    if (substr(line, 1, 3) != "- `") return "=" line
                    rest = substr(line, 4)
                    i = index(rest, "`: ")
                    if (i == 0) return "=" line
                    return substr(rest, 1, i - 1)
                }
                FNR == 1 { fileno++ }
                fileno == 1 {
                    if ($0 == head) { inside = 1; next }
                    if (inside && substr($0, 1, 3) == "## ") { inside = 0 }
                    if (inside && substr($0, 1, 3) == "- `") seen[key($0)] = 1
                    next
                }
                {
                    if ($0 == head) { mine = 1; next }
                    if (mine && substr($0, 1, 3) == "## ") { mine = 0 }
                    if (!mine || substr($0, 1, 3) != "- `") next
                    k = key($0)
                    if (k in seen) next
                    seen[k] = 1
                    print
                }
            ' "$file" "$cache_file" > "$WORK/missing"
            [ -s "$WORK/missing" ] || continue
            awk -v head="## $t" -v missfile="$WORK/missing" '
                BEGIN { n = 0; while ((getline l < missfile) > 0) miss[++n] = l }
                function release(   i) { for (i = 1; i <= held; i++) print hold[i]; held = 0 }
                function emit(   i) { if (inside && !done) { for (i = 1; i <= n; i++) print miss[i]; done = 1 } }
                {
                    if ($0 == head) { release(); print; inside = 1; next }
                    if (substr($0, 1, 3) == "## ") { emit(); release(); inside = 0; print; next }
                    if (inside && NF == 0) { hold[++held] = $0; next }
                    release(); print
                }
                END { emit(); release() }
            ' "$file" > "$WORK/merged"
            cat "$WORK/merged" > "$file"
        done
    elif [ -f "$local_file" ]; then
        cp "$local_file" "$file"
    elif [ -f "$cache_file" ]; then
        cp "$cache_file" "$file"
    else
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

printf '{"read": true, "count": %s, "days": %s, "entries": [%s]}\n' "$count" "$days" "$entries"
