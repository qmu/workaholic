#!/bin/sh
# THE ONE DERIVATION OF "IS NOW A TIME TO SPEAK" — sourced, never invoked.
#
#   . "${SCRIPT_DIR}/lib/speaking-window.sh"
#   speaking_window "<hour|>" "<weekday|>" "<tick|>"
#   # sets SW_QUIET SW_OFFDAY SW_WINDOW SW_ZONE SW_WORK_DAYS SW_HOUR SW_WEEKDAY SW_TODAY
#
# WHY IT WAS LIFTED OUT (2026-09-01, the developer's instruction). `ask-question.sh` computed
# this window and honoured it; `render-tick-post.sh` did not know it existed. So the two halves
# of one tick disagreed about whether anyone was listening, and the measured result was a root
# posted into `#coop-planner` at **04:01 JST** carrying `質問 0 件` while the same tick held
# **seventeen** questions — six expiring directions and two blocked retirements — every one of
# them refused `quiet_hours` by this window. The loop woke the channel to say something addressed
# to nobody, and held back the only things that were addressed to someone.
#
# A status line addressed to nobody is what `🔧 Needs a decision` and `📦 Release Preparation`
# were retired for. Posting one at 4am is that same shape with the volume turned up, and it
# reached the channel through a gate that had simply never been told about the window.
#
# ONE DERIVATION, TWO CONSUMERS, and the values are the check-in gate's own
# (`WORKAHOLIC_QUIET_HOURS`, `WORKAHOLIC_WORK_DAYS`, `WORKAHOLIC_QUIET_TZ`) rather than a second
# set: a root and a question that could disagree about the hour is the defect this fixes, and
# two copies of the arithmetic is how it would come back.
#
# THE CALLER MAY PASS AN HOUR AND A WEEKDAY (the drills do), and a tick id supplies the day so a
# re-entered tick answers the same way twice — the reason `ask-question.sh` already read its day
# from the tick rather than from the wall clock.

# THE OPERATOR'S ZONE, derived once. `speaking_window` reads it below, and so does
# `lib/tick-thread-key.sh`, which needs the day a reader perceives without needing to know
# whether that reader is awake. The hour somebody is listening and the day they are having
# are the same clock, and a second `WORKAHOLIC_QUIET_TZ` read is how the two would drift —
# the defect this whole file was lifted out to fix, one unit larger.
speaking_zone() {
    printf '%s' "${WORKAHOLIC_QUIET_TZ:-Asia/Tokyo}"
}

speaking_window() {
    _sw_hour="${1:-}"
    _sw_weekday="${2:-}"
    _sw_tick="${3:-}"

    SW_ZONE=$(speaking_zone)
    SW_WINDOW="${WORKAHOLIC_QUIET_HOURS:-22-08}"
    SW_WORK_DAYS="${WORKAHOLIC_WORK_DAYS:-1-5}"

    _sw_start=$(printf '%s' "$SW_WINDOW" | cut -d- -f1)
    _sw_end=$(printf '%s' "$SW_WINDOW" | cut -d- -f2)

    [ -n "$_sw_hour" ] || _sw_hour=$(TZ="$SW_ZONE" date +%H)
    _sw_hour=$(printf '%s' "$_sw_hour" | sed 's/^0//')
    [ -n "$_sw_hour" ] || _sw_hour=0
    SW_HOUR="$_sw_hour"

    _sw_dstart=$(printf '%s' "$SW_WORK_DAYS" | cut -d- -f1)
    _sw_dend=$(printf '%s' "$SW_WORK_DAYS" | cut -d- -f2)
    [ -n "$_sw_weekday" ] || _sw_weekday=$(TZ="$SW_ZONE" date +%u)
    case "$_sw_weekday" in ''|*[!0-9]*) _sw_weekday=1 ;; esac
    SW_WEEKDAY="$_sw_weekday"

    SW_OFFDAY=false
    if [ "$SW_WEEKDAY" -lt "$_sw_dstart" ] || [ "$SW_WEEKDAY" -gt "$_sw_dend" ]; then SW_OFFDAY=true; fi

    SW_TODAY=$(printf '%s' "$_sw_tick" | sed -n 's/^\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)-.*/\1-\2-\3/p')
    [ -n "$SW_TODAY" ] || SW_TODAY=$(TZ="$SW_ZONE" date +%Y-%m-%d)

    SW_QUIET=false
    if [ "$_sw_start" -gt "$_sw_end" ]; then
        # The window crosses midnight, which is the normal case for "late night".
        if [ "$SW_HOUR" -ge "$_sw_start" ] || [ "$SW_HOUR" -lt "$_sw_end" ]; then SW_QUIET=true; fi
    else
        if [ "$SW_HOUR" -ge "$_sw_start" ] && [ "$SW_HOUR" -lt "$_sw_end" ]; then SW_QUIET=true; fi
    fi
}
