#!/bin/sh -eu
# The DEFAULT target date for a direction the ask did not date: one week from the ask.
#
# Usage: default-target-date.sh [<ask-date>]
# Output: {"ok": true, "target_date": "YYYY-MM-DD", "basis": "YYYY-MM-DD", "days": 7}
#     or: {"ok": false, "reason": "bad_ask_date", "basis": "", "days": 7}
#
# WHY IT EXISTS (2026-08-30, mission `draft-a-dateless-direction-with-the-operator-s-one-week-default`).
# `/specificate`'s strategy form needs three parts FROM THE ASK ITSELF — a date, an owner, an aim
# with no decomposable plan — so an ask carrying two of them was record-only, `no_target_date`.
# Measured 2026-08-30: three announced directions all died there, their refusal traced only by a
# parenthetical addressed to nobody, while the loop kept planning from the directions that
# already existed. **The operator ruled the default on 2026-08-30: one week from the ask.**
#
# SEVEN LIVES HERE AND NOWHERE ELSE, which is the whole reason this is a script rather than a
# line in the caller. Every other date term in this layer (`days_to_target`, `overdue`,
# `expiring`) is derived in exactly one place and read by everything else; a "week" computed at
# two call sites is two clocks, and the second one is wrong the first time somebody edits it. A
# later reader who greps the constant lands on the operator's ruling and its date rather than on
# a bare number.
#
# IT DECIDES NO POLICY. It reads no strategy, writes nothing, and never says whether a default
# SHOULD be taken — that judgment is `/specificate`'s strategy form, which calls this only when
# the ask stated no date at all. An ask that states a date the run cannot parse stays
# `no_target_date`: defaulting over the operator's own words is the failure this must not
# introduce while removing the other one.
#
# IT COUNTS FROM THE ASK, NOT FROM THIS CLOCK, when the caller supplies one — the triggering
# issue's own date — so a tick that ingests a week-old issue does not date the direction from
# the hour it happened to run. `basis` reports which of the two it used, so a caller never has
# to guess whether its argument was honoured.
#
# A MALFORMED `<ask-date>` IS REFUSED WITH NO DATE EMITTED (`bad_ask_date`), never silently
# fallen back to today: a plausible answer hiding a malformed input is the shape that makes a
# defect invisible, and `create.sh` would accept the fallback without complaint.
#
# THE ARITHMETIC IS jq OVER EPOCH SECONDS, matching `survey-strategies.sh`'s own `days()`.
# `date -d` is GNU-only and `date -v` is BSD-only, so a shell-native computation works on the
# runner and not on a developer's machine, or the reverse.

set -eu

DAYS=7
ASK_DATE="${1:-}"

if [ -n "$ASK_DATE" ]; then
    case "$ASK_DATE" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
        *)
            printf '{"ok": false, "reason": "bad_ask_date", "basis": "", "days": %s}\n' "$DAYS"
            exit 0
            ;;
    esac
    BASIS="$ASK_DATE"
else
    BASIS="$(date -u +%Y-%m-%d)"
fi

# jq validates the basis a second time by construction: an unparseable date answers `null` and
# is refused here rather than emitted as a date nothing computed.
TARGET=$(printf '%s' "$BASIS" | jq -R -r --argjson days "$DAYS" '
    if test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")
    then (((. + "T00:00:00Z") | fromdateiso8601) + ($days * 86400)) | strftime("%Y-%m-%d")
    else "" end' 2>/dev/null || printf '')

if [ -z "$TARGET" ]; then
    printf '{"ok": false, "reason": "bad_ask_date", "basis": "", "days": %s}\n' "$DAYS"
    exit 0
fi

printf '{"ok": true, "target_date": "%s", "basis": "%s", "days": %s}\n' \
    "$TARGET" "$BASIS" "$DAYS"
