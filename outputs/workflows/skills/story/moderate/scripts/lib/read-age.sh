#!/bin/sh
# The one way a step attaches a condition's age to a candidate. Sourced, never executed.
#
# WHY IT IS A LIBRARY (2026-08-30, mission `say-how-long-the-loop-has-been-stuck`). Four
# question steps carry the age, and each needs the same three lines: call the reader, keep
# its answer verbatim, and name the one case the reader itself cannot answer for — a reader
# that is not present beside this skill. Four copies of that is four chances to write the
# fallback differently, and the difference that matters is precisely the one this mission
# exists to close: a reading we could not make rendered as a condition that just started.
#
# THE READER'S WORDS ARE CARRIED VERBATIM. Nothing here normalises, renames or re-derives a
# term: `condition-age.sh` owns the walk, its bound and its vocabulary, and a normalised
# word would send a reader to a string no script printed.
#
# LOSING THE AGE MUST NOT LOSE THE QUESTION. The age is evidence ON a question, never the
# reason the question exists, so a missing or unparseable reader yields a NAMED unreadable
# age and the candidate stands. That direction is deliberate: an over-eager question beats a
# silently dropped one (`ci-retirement-turn.sh`'s discipline).
#
# Usage: . <this file>; age=$(read_age "<key>" "<repo-root>")

read_age() {
    _ra_key="${1:-}"
    _ra_root="${2:-.}"
    _ra_script="${READ_AGE_SCRIPT:-${SCRIPT_DIR:-.}/condition-age.sh}"
    if [ -n "$_ra_key" ] && [ -f "$_ra_script" ]; then
        _ra_out=$(sh "$_ra_script" --key "$_ra_key" --root "$_ra_root" 2>/dev/null || true)
        if [ -n "$_ra_out" ] && printf '%s' "$_ra_out" | jq -e . >/dev/null 2>&1; then
            printf '%s' "$_ra_out"
            return
        fi
    fi
    printf '{"first_seen": null, "ticks": null, "readable": false, "reason": "age_reader_unavailable"}'
}
