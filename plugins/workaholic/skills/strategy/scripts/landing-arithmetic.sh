#!/bin/sh -eu
# landing-arithmetic.sh — per direction, WHAT REMAINS against HOW LONG IS LEFT.
# Pure read: no file, no commit, no branch, no pull request, no merge, no network call.
# Exit 0 in every case, degraded included.
#
# Usage: landing-arithmetic.sh [window-days] [workaholic-root]
#   window-days: how many days of history the observed rate is measured over. Defaults to
#                the operator's own week, read from `default-target-date.sh` — see
#                THE WINDOW below.
#
# Output (one JSON object):
#   {readable, reason, window_days, date, empty_reason,
#    directions: [{slug, title, assignees, target_date, days_to_target,
#                  readable, reason,
#                  remaining: {queued, unchecked_acceptance, missions, missions_omitted},
#                  observed: {landed, window_days, per_day},
#                  needed_days, verdict}],
#    counted}
#
#   verdict          "clears" | "does_not_clear" | "no_target_date" | "unreadable"
#   `readable` is ABSENT on a completed read (the house convention `merge_policy` and
#   ticket `status:` already use: absent means it completed), so the test is
#   `readable == false` and never `readable // true` — in jq `false // true` is `true`,
#   which reads every degraded walk as a healthy one.
#
# WHY IT EXISTS (2026-09-01, ticket `20260901123357-say-which-directions-the-arithmetic-says-cannot-land`).
# The READING landed already: `/standup`'s digest names each direction, the missions serving
# it, each mission's acceptance `checked`/`total`, its queued count, and the whole queue.
# What nobody did was the ARITHMETIC over it. Measured the day this was filed: 30 queued
# tickets against three directions all dated the same day, six days out, and no reading
# anywhere in this repository said that will not land.
#
# IT COMPOSES; IT DOES NOT WALK. `standup/scripts/digest.sh` is the one place that already
# assembles, per direction, its missions with `checked`/`total`/`queued` and its
# `days_to_target`, over `strategy/scripts/attributed-work.sh` — the ONE reader of "which
# work belongs to strategy X". This script calls that reading and divides. It adds no second
# walker, parses no relation, and NO ARTIFACT GAINS A FIELD, which is the standing rule for
# this layer (`CLAUDE.md`, *The strategy layer*).
#
# THE CAPS ARE RAISED FOR THE READ, DELIBERATELY. `STANDUP_MAX_STRATEGIES` and
# `STANDUP_MAX_ITEMS` are RENDER caps — they bound what a morning post shows. An arithmetic
# computed over a truncated mission set would under-count what remains and answer "clears"
# for a direction it had not finished reading, which is the one wrong answer this must never
# give. `missions_omitted` is carried through anyway so a caller can see the read was whole.
#
# THE RATE IS THE DIRECTION'S OWN, NEVER A CONSTANT. "Will it land" needs a rate, and every
# way of supplying one from outside is the tunable constant this repository has refused
# before (`survey-strategies.sh` orders by stated terms and nothing else). So the rate is
# MEASURED: what this direction actually moved inside the window, divided by the window. A
# direction that has moved nothing reads `per_day: 0` and `does_not_clear` — which is the
# honest answer and not a special case.
#
# THE WINDOW is expressed in DAYS rather than as a `git log --since` expression, because the
# denominator has to be a number: dividing by "1 day ago" is not possible and parsing an
# arbitrary expression into days is the kind of guess that makes a wrong answer look
# computed. Its default is read from `default-target-date.sh`, where the operator's week
# already lives — SEVEN IS NOT RE-DECLARED HERE, and a later reader who greps the constant
# still lands on the operator's ruling and its date.
#
# TWO GRAINS, COUNTED SEPARATELY, AND ONLY ONE IS DIVIDED. Unchecked acceptance items and
# queued tickets are not the same unit. The observed rate counts ARTIFACTS that moved, so
# `queued` is the numerator the arithmetic can honestly divide, and
# `unchecked_acceptance` rides beside it as the other thing remaining — reported, never
# folded in. A direction with acceptance still open and nothing queued therefore reads
# `clears` on the arithmetic while `unchecked_acceptance` says what is still open; that is
# the reading being precise about what it measured, not hiding the rest.
#
# A DEGRADED READ IS NAMED WITH NULL COUNTS, NEVER ZEROS. A zero reads as "nothing remains",
# which is the opposite of "I could not see". A direction whose attribution walk failed, or
# any of whose missions could not be read, carries `readable: false`, its own reason, null
# counts and `verdict: "unreadable"`. It is never given a landing verdict — a wrong "this
# will land" is the answer that costs the operator the date.
#
# A DATELESS DIRECTION IS NAMED, NOT RANKED. With no `target_date` there is no denominator;
# such a direction reports what remains, `days_to_target: null` and
# `verdict: "no_target_date"`. Inventing a date would rank it against dated directions on a
# number nothing measured.
#
# IT IS EVIDENCE AND RANKS AND GATES NOTHING. Nothing here holds work, orders an offer,
# closes a mission, moves a stage or writes a strategy. `escalate-a-date-that-will-not-hold`
# asks a person about a `does_not_clear` direction; that step is the consumer, and the
# question is the only act anybody takes on this.
#
# ATTRIBUTION IS TRANSITIVE AND LOSSY (`attributed-work.sh`, `exhaustive: false`), so work
# no direction claims is outside this reading BY CONSTRUCTION — a mission nothing attributed
# contributes to no direction's remainder here. `counted` reports the direction total this
# read covered so a surprising answer is read as the limit it is rather than as a defect.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
DIGEST="${SCRIPT_DIR}/../../standup/scripts/digest.sh"
DEFAULT_DATE="${SCRIPT_DIR}/default-target-date.sh"

ROOT="${2:-.workaholic}"
TODAY=$(date -u +%Y-%m-%d)

emit_top() {
    # $1 = readable ("true"/"false"), $2 = reason, $3 = directions JSON, $4 = counted,
    # $5 = empty_reason
    jq -nc --argjson readable "$1" --arg reason "$2" --argjson dirs "$3" \
        --argjson counted "$4" --arg empty "$5" \
        --argjson window "$WINDOW_DAYS" --arg date "$TODAY" '
        {window_days: $window, date: $date,
         directions: $dirs, counted: $counted, empty_reason: $empty}
        + (if $readable then {} else {readable: false, reason: $reason} end)'
}

# --- The window ---------------------------------------------------------------------
# The operator's week, read from the one place it is declared. A caller may override it
# with an explicit day count; anything that is not a positive integer is refused rather
# than silently defaulted, because a window nobody chose is a denominator nobody chose.
WINDOW_DAYS="${1:-}"
if [ -z "$WINDOW_DAYS" ]; then
    WINDOW_DAYS=$(sh "$DEFAULT_DATE" 2>/dev/null | jq -r '.days' 2>/dev/null || printf '')
fi
case "$WINDOW_DAYS" in
    ''|*[!0-9]*|0)
        WINDOW_DAYS=0
        emit_top false bad_window '[]' 'null' ''
        exit 0
        ;;
esac

# --- The reading this derives over ---------------------------------------------------
# One call. The render caps are raised so the arithmetic sees every direction and every
# mission (see THE CAPS ARE RAISED above); nothing else about the digest is changed.
if ! DIG=$(STANDUP_MAX_STRATEGIES=100000 STANDUP_MAX_ITEMS=100000 \
        sh "$DIGEST" "${WINDOW_DAYS} days ago" "$ROOT" 2>/dev/null); then
    emit_top false digest_unreadable '[]' 'null' ''
    exit 0
fi

# The digest's own two silent exits are its answers, not ours. `strategy_list_unreadable`
# is a degraded read and is reported as one; `no_strategies` is a real, complete answer
# about a repository with no direction and carries no verdict for anybody.
NOOP_REASON=$(printf '%s' "$DIG" | jq -r '.noop_reason // ""')
if [ "$NOOP_REASON" = "strategy_list_unreadable" ]; then
    emit_top false strategy_list_unreadable '[]' 'null' ''
    exit 0
fi

# --- The arithmetic -------------------------------------------------------------------
# Everything below is one jq program over the digest's own record set, so there is no
# second pass over the tree and no place for a second reading to disagree with the first.
DIRECTIONS=$(printf '%s' "$DIG" | jq -c --argjson window "$WINDOW_DAYS" '
    [ .strategies[]
      | . as $s
      # A mission grain that could not be read poisons the direction total, and that is
      # deliberate: summing the readable ones would answer a smaller remainder with the
      # same confidence as a whole read.
      | ([$s.missions[]? | select(.readable == false)] | length) as $bad_missions
      | (if $s.readable == false then false
         elif $bad_missions > 0 then false
         else true end) as $ok
      | (if $s.readable == false then ($s.reason // "attribution_unreadable")
         elif $bad_missions > 0 then ([$s.missions[]? | select(.readable == false) | .reason] | first)
         else "" end) as $why
      | (if $ok then ([$s.missions[]? | .queued] | add // 0) else null end) as $queued
      | (if $ok then ([$s.missions[]? | (.total - .checked)] | add // 0) else null end) as $unchecked
      # THE NUMERATOR IS TICKETS THAT LEFT THE QUEUE, not artifacts that were touched.
      # `active_count` counts every attributed artifact that changed in the window — a
      # mission file a changelog append rewrote, a story the report wrote — and measured
      # on this repository it read 502 against 50 queued, so every direction cleared by
      # construction and the reading said nothing. The remainder is queued TICKETS, so
      # the rate has to be the same unit: tickets that reached `done` inside the window.
      | (if $ok then ([$s.moved[]? | select(.kind == "ticket" and .state == "done")] | length)
         else null end) as $landed
      | (if $ok then (($landed / $window) * 1000 | round) / 1000 else null end) as $per_day
      | (if $ok and $per_day != null and $per_day > 0 and $queued != null and $queued > 0
         then (($queued / $per_day) | ceil) else null end) as $needed
      | (if $ok | not then "unreadable"
         elif $s.days_to_target == null then "no_target_date"
         elif $queued == 0 then "clears"
         elif $s.days_to_target < 0 then "does_not_clear"
         elif $per_day == 0 then "does_not_clear"
         elif $needed <= $s.days_to_target then "clears"
         else "does_not_clear" end) as $verdict
      | {slug: $s.slug, title: $s.title, assignees: ($s.assignees // []),
         target_date: $s.target_date, days_to_target: $s.days_to_target,
         readable: $ok, reason: $why,
         remaining: {queued: $queued, unchecked_acceptance: $unchecked,
                     missions: (if $ok then ($s.missions | length) else null end),
                     missions_omitted: ($s.missions_omitted // 0)},
         observed: {landed: $landed, window_days: $window, per_day: $per_day},
         needed_days: $needed,
         verdict: $verdict} ]' 2>/dev/null || printf '')

if [ -z "$DIRECTIONS" ]; then
    emit_top false arithmetic_unreadable '[]' 'null' ''
    exit 0
fi

COUNTED=$(printf '%s' "$DIRECTIONS" | jq -c '
    {directions: length,
     readable: ([.[] | select(.readable)] | length),
     unreadable: ([.[] | select(.readable | not)] | length),
     does_not_clear: ([.[] | select(.verdict == "does_not_clear")] | length),
     clears: ([.[] | select(.verdict == "clears")] | length),
     no_target_date: ([.[] | select(.verdict == "no_target_date")] | length)}')

EMPTY=""
if [ "$NOOP_REASON" = "no_strategies" ]; then EMPTY="no_strategies"; fi

emit_top true '' "$DIRECTIONS" "$COUNTED" "$EMPTY"
