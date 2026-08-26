#!/bin/sh
# The one derivation of a tick id's ISO8601 timestamp. Sourced, never executed.
#
# WHY IT IS A LIBRARY, AND WHY IT VALIDATES (2026-08-26). Two steps convert a tick id
# into the window they read under — `step-inbound-sweep.sh` (`?since=`) and
# `step-doc-drift.sh` (`git rev-list --before=`) — and both did it with the same
# unvalidated `sed` substitution, copied. A tick id is normally minted by `tick-id.sh`
# from the UTC clock, so the substitution was safe by assumption; the assumption is not
# the log's, which is append-only and carries whatever any tick ever wrote.
#
# MEASURED (2026-08-26). The committed log carried a section `## 20260819-999999` — a
# sentinel id, not a clock. `log-read.sh` returns the newest entry and `999999` sorts
# last, so from 2026-08-19 onward every tick derived its window as
# `2026-08-19T99:99:99Z`. GitHub answered `422 The since parameter needs to be in ISO
# 8601 format` for seven days of sweeps, and `git rev-list --before` matched nothing, so
# `doc-drift` reported `no_baseline` and the documentation check never ran once. Both
# steps reported themselves healthy throughout: the sweep because it read the 422 body
# as a row, the drift check because `no_baseline` is a legitimate answer on a young
# repository. An hourly tick that reports "nothing to do" when it could not look is the
# one failure this skill's standing rules name by name.
#
# THE FALLBACK IS THE DAY START, NOT THE RAW STRING. An id that does not validate is a
# window this tick cannot trust, so the caller falls back to the tick's own day start —
# the same fallback it already takes when no previous tick exists — and reports the
# reason, so a poisoned log entry costs one wide window rather than seven silent days.
# Nothing here rewrites the log: it is append-only, and a machine that pruned a line it
# disliked is a worse failure than the one it would cure.
#
# Usage: . <this file>
#   iso=$(tick_to_iso "<tick-id>")   full timestamp, empty when the id is not one
#   iso=$(tick_day_iso "<tick-id>")  that id's UTC day start, empty when even the day is not one

# `YYYYMMDD-HHMMSS`, with each field inside its calendar range. Empty output means "this
# is not a timestamp" — the caller decides what to do about it, and every caller here
# names the reason rather than substituting a guess.
tick_to_iso() {
    _ti_id="${1:-}"
    case "$_ti_id" in
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
        *) return 0 ;;
    esac
    _ti_mo=$(printf '%s' "$_ti_id" | cut -c5-6)
    _ti_dy=$(printf '%s' "$_ti_id" | cut -c7-8)
    _ti_hh=$(printf '%s' "$_ti_id" | cut -c10-11)
    _ti_mi=$(printf '%s' "$_ti_id" | cut -c12-13)
    _ti_ss=$(printf '%s' "$_ti_id" | cut -c14-15)
    # Range only, never a calendar: whether 2026-02-30 exists is git's and GitHub's
    # question, and a step that answered it would be a second, partial date library.
    [ "$_ti_mo" -ge 1 ] 2>/dev/null && [ "$_ti_mo" -le 12 ] || return 0
    [ "$_ti_dy" -ge 1 ] 2>/dev/null && [ "$_ti_dy" -le 31 ] || return 0
    [ "$_ti_hh" -le 23 ] 2>/dev/null || return 0
    [ "$_ti_mi" -le 59 ] 2>/dev/null || return 0
    [ "$_ti_ss" -le 59 ] 2>/dev/null || return 0
    printf '%s-%s-%sT%s:%s:%sZ' \
        "$(printf '%s' "$_ti_id" | cut -c1-4)" "$_ti_mo" "$_ti_dy" "$_ti_hh" "$_ti_mi" "$_ti_ss"
}

# The tick's own day start. The time half is never read, so an id whose clock is a
# sentinel still yields a usable window as long as its date is one.
tick_day_iso() {
    _td_id="${1:-}"
    case "$_td_id" in
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-*) ;;
        *) return 0 ;;
    esac
    _td_mo=$(printf '%s' "$_td_id" | cut -c5-6)
    _td_dy=$(printf '%s' "$_td_id" | cut -c7-8)
    [ "$_td_mo" -ge 1 ] 2>/dev/null && [ "$_td_mo" -le 12 ] || return 0
    [ "$_td_dy" -ge 1 ] 2>/dev/null && [ "$_td_dy" -le 31 ] || return 0
    printf '%s-%s-%sT00:00:00Z' "$(printf '%s' "$_td_id" | cut -c1-4)" "$_td_mo" "$_td_dy"
}
