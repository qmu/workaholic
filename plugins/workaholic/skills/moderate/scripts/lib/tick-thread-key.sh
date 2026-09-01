#!/bin/sh
# THE ONE DERIVATION OF THE `🔎 Moderation` ROOT'S THREAD KEY — sourced, or run directly.
#
#   . "${SCRIPT_DIR}/lib/tick-thread-key.sh"
#   tick_thread_key "<tick-id>"          # sets TTK_KEY and TTK_REASON; prints nothing
#   sh lib/tick-thread-key.sh <tick-id>  # prints {"key": "...", "tick": "...", "reason": "..."}
#
# ═══ WHY THE KEY COULD NEVER MATCH ═══════════════════════════════════════════════
#
# The root was keyed `tick:<tick-id>` where the id is that tick's own timestamp, so
# `tick:20260901-160000` can never equal `tick:20260901-150000` and the stateless
# exact-string lookup in `workaholic:notify` took case 4 — OPEN A NEW ROOT — every hour,
# by construction. Nothing was broken; the key simply named the hour rather than the
# conversation. Measured on a consuming repository: 14 roots in one window, 12 of them
# carrying zero questions.
#
# Keying on the DAY makes the machinery that already exists — reply into the thread the
# lookup found — reachable for the first time. This file changes the key and nothing
# else; the posting behaviour it unlocks is its own ticket.
#
# ═══ THE DAY IS THE OPERATOR'S, NOT UTC ══════════════════════════════════════════
#
# A tick id is minted from the UTC clock and the log's day files are UTC, but the day a
# READER perceives is `WORKAHOLIC_QUIET_TZ` — the same clock that already decides whether
# anyone is awake to read it (`lib/speaking-window.sh`). Keying on UTC would break a root
# mid-evening for a JST reader, which is the middle of their working day.
#
# THE COST IS STATED RATHER THAN HIDDEN: the key and the log day file can name different
# days for the same tick. That is correct — they answer different questions. The log is a
# maintainer's audit trail and stays UTC; the key names a conversation a person is having.
#
# The zone is read through `speaking_zone`, in `lib/speaking-window.sh`, and NOT from the
# environment again: a root and a question that could disagree about the day is the same
# defect that file was lifted out to fix, one unit larger.
#
# ═══ IT READS NO CLOCK OF ITS OWN ════════════════════════════════════════════════
#
# The key is a function of the tick id and the zone, and of nothing else. A re-entered
# tick derives the same key twice, and a drill can hand it any id and get a stable answer.
# There is deliberately no `date +%Y%m%d` fallback: a key derived from *now* rather than
# from the tick would thread an hour into whichever day the container happened to wake in.
#
# ═══ AN UNREADABLE ID REFUSES BY NAME ════════════════════════════════════════════
#
# `lib/tick-iso.sh` already records why a tick id is an INPUT rather than a guarantee: the
# log is append-only and carries whatever any tick ever wrote, and a sentinel id
# (`20260819-999999`) once cost seven days of blind windows. An id that does not validate
# answers `TTK_REASON` with no key at all. A key derived from a date this could not read
# would thread an hour into the WRONG day's root, which is worse than opening a new one —
# the caller falls back to naming the tick, exactly as it did before this file existed.

# Resolve the sibling libraries. When SOURCED, `$0` is the caller (in `scripts/`), so the
# libraries sit under `<dir>/lib`; when RUN DIRECTLY, `$0` is this file (in `scripts/lib/`)
# and they are alongside. Both are tried, in that order, rather than assuming either.
_ttk_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
for _ttk_base in "${_ttk_dir}/lib" "${_ttk_dir}"; do
    if [ -f "${_ttk_base}/tick-iso.sh" ] && [ -f "${_ttk_base}/speaking-window.sh" ]; then
        . "${_ttk_base}/tick-iso.sh"
        . "${_ttk_base}/speaking-window.sh"
        break
    fi
done

# Sets TTK_KEY (the key, or empty) and TTK_REASON (empty on success). Exit 0 always: an
# unreadable id is an answer this caller must render, never a failure that stops the tick.
tick_thread_key() {
    TTK_KEY=''
    TTK_REASON=''
    _ttk_id="${1:-}"

    if [ -z "$_ttk_id" ]; then
        TTK_REASON='no_tick'
        return 0
    fi

    # The full timestamp, not `tick_day_iso`: the day half alone would accept a sentinel
    # clock, and converting a sentinel into the operator's zone is precisely the guess this
    # refuses to make.
    _ttk_iso=$(tick_to_iso "$_ttk_id")
    if [ -z "$_ttk_iso" ]; then
        TTK_REASON='tick_not_a_timestamp'
        return 0
    fi

    _ttk_day=$(TZ="$(speaking_zone)" date -d "$_ttk_iso" +%Y%m%d 2>/dev/null || true)
    case "$_ttk_day" in
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;;
        *)
            # A `date` that cannot convert (no `-d`, an unknown zone) is the ABSENCE of a
            # reading, named as one. Falling back to the UTC day would be a key derived
            # from a zone nobody asked for.
            TTK_REASON='zone_conversion_failed'
            return 0
            ;;
    esac

    TTK_KEY="tick-day:${_ttk_day}"
}

# Run directly (the ticket's own verification method) → one JSON object. Sourced → nothing.
case "$0" in
    *tick-thread-key.sh)
        tick_thread_key "${1:-}"
        printf '{"key": "%s", "tick": "%s", "reason": "%s"}\n' "$TTK_KEY" "${1:-}" "$TTK_REASON"
        ;;
esac
