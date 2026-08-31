#!/bin/sh -eu
# How long has this condition been standing? — the one reader of a subject's age.
#
# WHY IT EXISTS (2026-08-30, mission `say-how-long-the-loop-has-been-stuck`). Every reading
# in this repository is instantaneous: `stalled`, `report_undelivered`, `retire-blocked`,
# an undrivable unit — each says WHAT is stuck and none says HOW LONG. A person reading one
# of the tick's questions cannot tell a condition that started this hour from one that has
# been true for eleven days, and the asked-once gate means they are told exactly once
# either way. Measured: five queued tickets stamped with an address the identity mapping
# does not name, undrivable since 2026-08-19, each asked about once — days ago.
#
# WHAT IT READS, AND WHY NOT THE STEP SUMMARY. The obvious source is the owning step's own
# log summary, and it is only satisfiable for `retire-claims`: `undrivable-units`,
# `undelivered-units` and `stalled-units` carry counts only, and each of those steps' own
# headers records that putting per-unit detail or an age in a summary is a CORRECTNESS
# violation — `render-tick-post.sh`'s changed-step diff would then mark the step changed
# every tick, which is the retired `📦 Release Preparation` shape. So the age is read from
# the QUESTION LEDGER the subject key already writes: `human-checkin-ask-<slug>` and
# `human-checkin-reasked-<slug>`, written exactly once per key by `ask-question.sh
# --record-ask` and never moved afterwards.
#
# WHAT THE READING MEANS, STATED SO IT IS NOT OVER-READ. It is the age of THE QUESTION,
# which is a LOWER BOUND on the age of the condition: a blocker that existed before anybody
# asked reads younger than it is. That is the honest direction — understating an age asks a
# person to look sooner than the truth would — and a consumer must say "asked about since"
# rather than asserting how long the artifact itself has been stuck.
#
# ABSENT IS NOT DEGRADED. A key the ledger has never carried is an ordinary state — this is
# the first time anybody is being asked — and answers `first_seen: null`, `ticks: 0` with no
# `readable` field at all. Only a log that EXISTS and could not be read answers
# `readable: false` with a named reason and NULL counts, never zeroed ones
# (`unattributed-work.sh`'s rule): a read we could not make must never render as a reading
# we made, and here the collapse would render an eleven-day blocker as one that just started.
#
# ABSENT MEANS COMPLETED. `readable` is emitted only when it is `false`, the convention
# `merge_policy` (absent means review) and a ticket's `status:` (absent means queued)
# already use — so every completed reading is byte-identical for a consumer not yet taught
# the term, and every test is `readable == false`, never `readable // true`, because jq
# treats `false` itself as empty.
#
# NO DATE ARITHMETIC. `ticks` counts the DISTINCT ticks the log holds at or after
# `first_seen`, compared lexically on the tick id (`YYYYMMDD-HHMMSS`, fixed width, sorts
# correctly by construction). Never a wall-clock difference: `date -d` is GNU-only and
# `date -v` is BSD-only, and `log-read.sh`'s own header refuses the arithmetic by name.
#
# THE WALK IS BOUNDED, AND A BOUNDED WALK SAYS SO. The tick log is append-only and NEVER
# pruned by a machine (`log-append.sh`'s own contract — deleting a day file is the
# operator's act), so an unbounded walk gets more expensive forever.
# `WORKAHOLIC_CONDITION_AGE_MAX_DAYS` (default 30) caps it; a non-numeric or empty value
# falls back to the default rather than failing, because the bound is a COST CONTROL and
# not a gate.
#
# THE BOUND IS NOT A COMPUTED DATE. It is expressed as THE NEWEST N DAY FILES, selected
# lexically from names that sort correctly by construction, and the Nth-newest file's own
# day is handed to `log-read.sh`'s existing `--since`. No arithmetic, and `log-read.sh` is
# untouched — a `--last-days` option there would put a second bounding concept beside
# `--since` in the one reader every other consumer shares, for one caller's benefit.
#
# `truncated` IS NOT A DEGRADATION. The walk was cut, not failed: `readable` stays absent
# and the counts stay real numbers. What it changes is the STANDING of `first_seen`, which
# becomes a floor (`first_seen_is_floor`) so a consumer renders *at least* rather than a
# date it could not establish. The field's shape does not move and no prose prefix is
# overloaded onto it: a consumer parsing prose is how two readings drift.
#
# ITS DIRECTION OF ERROR IS STATED BECAUSE IT IS ONE-SIDED. The bound can only make an age
# look YOUNGER — a key whose every ledger line fell outside the bound reads as an ordinary
# absence, and one with lines on both sides reads from the newer. Younger asks a person to
# look SOONER than the truth would, which is the safe direction, and it is the same
# direction the reading's own lower-bound nature already errs in.
#
# IT OWNS NOTHING ELSE. `log-read.sh` is the log's only parser and `lib/question-id.sh` the
# question id's one derivation; this composes both and adds no store, no cursor, no second
# walker and no field on any artifact. It is a pure read: no write, no network, no
# `plan-units.sh`, no `gh`. Exit 0 on every path, including a refusal.
#
# Usage: condition-age.sh --key <subject-key> [--root <repo-root>]
# Env:   WORKAHOLIC_CONDITION_AGE_MAX_DAYS (default 30) — the newest N day files to walk
# Output: one JSON line
#   {"key","slug","first_seen": "<tick-id>|null", "ticks": <n>}
#     plus "truncated": true and, with a first_seen, "first_seen_is_floor": true
#   {"key","slug","first_seen": null, "ticks": null, "readable": false, "reason": "<why>"}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
. "${SCRIPT_DIR}/lib/question-id.sh"
LOG_READ="${SCRIPT_DIR}/log-read.sh"

KEY=''
ROOT='.'
while [ $# -gt 0 ]; do
    case "$1" in
        --key)  KEY="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

SLUG=''
TRUNCATED=0

emit_ok() {
    # $1 first_seen (a tick id, or the literal `null`), $2 ticks
    _tail=''
    # Absent means the walk was complete, the convention `readable` above uses: a consumer
    # not taught the term reads a bounded-but-uncut walk exactly as it read an unbounded one.
    [ "$TRUNCATED" -eq 1 ] && _tail=', "truncated": true'
    if [ "$1" = 'null' ]; then
        printf '{"key": "%s", "slug": "%s", "first_seen": null, "ticks": %s%s}\n' \
            "$KEY" "$SLUG" "$2" "$_tail"
    else
        # A floor is only meaningful over a date we actually have. On a null reading the
        # bound is already said by `truncated`, and "at least null" is not a sentence.
        [ "$TRUNCATED" -eq 1 ] && _tail="${_tail}, \"first_seen_is_floor\": true"
        printf '{"key": "%s", "slug": "%s", "first_seen": "%s", "ticks": %s%s}\n' \
            "$KEY" "$SLUG" "$1" "$2" "$_tail"
    fi
    exit 0
}

emit_degraded() {
    printf '{"key": "%s", "slug": "%s", "first_seen": null, "ticks": null, "readable": false, "reason": "%s"}\n' \
        "$KEY" "$SLUG" "$1"
    exit 0
}

[ -n "$KEY" ] || emit_degraded no_key
[ -f "$LOG_READ" ] || emit_degraded reader_missing

SLUG=$(question_slug "$KEY")

# The log area's own state, before anything parses it. A path that does not exist is a
# repository with no tick history — the key has never been asked, an ordinary absence. A
# path that exists and is not a readable directory is our own degradation, and the two must
# not render alike.
# THE LOCATION RESOLVES THROUGH `log-read.sh`, NOT HERE (2026-08-31, mission
# `take-the-moderation-tick-s-log-off-main`). This script walked the directory itself, which
# after the log moved to its own ref would have read an EMPTY directory and answered "the key
# has never been asked" -- an ordinary absence -- for a log it simply had not fetched.
LOG_DIR=$(sh "$LOG_READ" --root "$ROOT" --log-dir 2>/dev/null \
    | sed -n 's/.*"log_dir": "\([^"]*\)".*/\1/p')
[ -n "$LOG_DIR" ] || emit_degraded log_unreadable
if [ -e "$LOG_DIR" ]; then
    { [ -d "$LOG_DIR" ] && [ -r "$LOG_DIR" ] && [ -x "$LOG_DIR" ]; } || emit_degraded log_unreadable
fi

# THE BOUND: the newest N day files, by name. `log-read.sh` validates the same shape, and
# the names sort correctly by construction, so the Nth-newest is a `sort | tail | head` and
# never a date computation.
MAX_DAYS="${WORKAHOLIC_CONDITION_AGE_MAX_DAYS:-30}"
case "$MAX_DAYS" in
    ''|*[!0-9]*) MAX_DAYS=30 ;;
esac
[ "$MAX_DAYS" -gt 0 ] 2>/dev/null || MAX_DAYS=30

# THE DAY LISTING IS THE RESOLVER'S TOO -- the union of the ref's copy and this container's
# own, which is the set a bound must be applied to. Walking one source would silently narrow
# the window to whichever half this container happened to hold.
SINCE=''
day_names=$(sh "$LOG_READ" --root "$ROOT" --list-days 2>/dev/null \
    | tr ',' '\n' | sed -n 's/.*"\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)".*/\1/p' | sort || true)
if [ -n "$day_names" ]; then
    n_days=$(printf '%s' "$day_names" | grep -c . 2>/dev/null || printf 0)
    if [ "$n_days" -gt "$MAX_DAYS" ]; then
        # Truncated exactly when a day file older than the cut exists — the walk was CUT,
        # rather than merely bounded by a log shorter than the bound.
        SINCE=$(printf '%s\n' "$day_names" | tail -n "$MAX_DAYS" | head -n 1)
        TRUNCATED=1
    fi
fi

read_step() { sh "$LOG_READ" --root "$ROOT" ${SINCE:+--since "$SINCE"} --step "$1" 2>/dev/null || true; }

asked_out=$(read_step "human-checkin-ask-${SLUG}")
reask_out=$(read_step "human-checkin-reasked-${SLUG}")

# The reader always emits an envelope, so nothing at all means it could not run.
[ -n "$asked_out" ] || emit_degraded log_unreadable

log_refusal=$(printf '%s' "$asked_out" | jq -r 'if (.read == false) then (.reason // "log_unreadable") else "" end' 2>/dev/null || printf '')
case "$log_refusal" in
    '') ;;
    # A repository whose tick log has never been written has asked nothing — the same
    # reading `question-state.sh` makes of a missing log, and an ordinary absence here.
    no_log_area) emit_ok null 0 ;;
    *) emit_degraded "$log_refusal" ;;
esac

# The earliest tick across the ask and its one bounded re-ask. Both are posts of the same
# question, and the first of them is when this subject started being asked about.
first_seen=$(printf '%s\n%s' "$asked_out" "$reask_out" \
    | jq -rs '[.[]?.entries[]?.tick] | map(select(. != null and . != "")) | sort | first // ""' 2>/dev/null || printf '')

[ -n "$first_seen" ] || emit_ok null 0

# Distinct ticks at or after `first_seen`. `--since` bounds the file walk to the day the
# question first appeared; the lexical tick comparison does the rest, so a tick earlier on
# that same day is not counted.
first_day=$(printf '%s\n%s' "$asked_out" "$reask_out" \
    | jq -rs --arg t "$first_seen" '[.[]?.entries[]? | select(.tick == $t) | .day] | first // ""' 2>/dev/null || printf '')

all_out=$(sh "$LOG_READ" --root "$ROOT" ${first_day:+--since "$first_day"} 2>/dev/null || true)
[ -n "$all_out" ] || emit_degraded log_unreadable

ticks=$(printf '%s' "$all_out" \
    | jq --arg t "$first_seen" '[.entries[]? | .tick | select(. != null and . >= $t)] | unique | length' 2>/dev/null || printf '')
[ -n "$ticks" ] || emit_degraded log_unreadable

emit_ok "$first_seen" "$ticks"
