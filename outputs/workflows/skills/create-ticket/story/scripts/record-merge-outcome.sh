#!/bin/sh -eu
# Record a `review` unit's merge outcome into its own branch story, so the reading survives
# the run that made it.
#
# WHY IT EXISTS (2026-08-27, mission `close-the-units-the-loop-already-finished`). §6's route
# reports the merge outcome per unit, and that report lives in the run's stdout — which dies
# with the container. The claim oracle then cannot tell the loop's own undelivered work from a
# unit legitimately waiting on a person: both are drained, both reported, both sit at an open
# pull request, and `claimed_reported` covered both. The split needs a durable answer to *why
# is this pull request still open*, and the honest one is the answer the run that tried already
# had.
#
# THE STORY IS THE HOME, AND NO NEW ARTIFACT IS CREATED. `.workaholic/stories/<branch>.md` is
# already the branch's own record, already committed at the tip by the seam that opens the pull
# request, and already what `claims_has_story` reads to know the unit reported at all. Reading
# one more section out of a blob the oracle already fetches costs no network call and no second
# lookup — which is the constraint the consuming ticket states outright, because a wrong verdict
# here releases work still in flight.
#
# ONLY A MERGE THAT DID NOT LAND IS RECORDED. A merged unit's branch is released by the merge,
# so the oracle never sees it and a record of success would be written where nothing reads it.
#
# IT IS APPENDED, NOT MERGED INTO PROSE, and it is IDEMPOTENT per outcome: re-running with the
# same outcome rewrites nothing, and a later run recording a *different* outcome replaces the
# section rather than stacking a second one — the question is "what is true now", and two
# answers in one file is the ambiguity this exists to remove.
#
# Usage: record-merge-outcome.sh <story-file> <outcome>
#   <outcome> is §6's vocabulary verbatim: `merge_refused: <merge-reason.sh word>` or
#   `merge_not_attempted: <hard|confirm>`. It is NOT validated against a list here — the route
#   owns the vocabulary and a second copy of it is a second thing to keep in step — but it must
#   be one line, because the reader takes one line.
# Output: {"recorded": bool, "story": "...", "outcome": "...", "changed": bool, "reason": ""}

set -eu

story="${1:-}"
outcome="${2:-}"

# THE OUTCOME IS ECHOED BACK SANITIZED, and that is not cosmetic: the one input this script
# refuses for being multi-line was being interpolated raw into the refusal, so the refusal
# itself was invalid JSON and a caller parsing it got a syntax error instead of the reason.
# Backslashes and quotes are escaped and every control character becomes a space, so every
# emission is parseable whatever was passed in.
json_str() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n\r\t' '   '
}

emit() {
    printf '{"recorded": %s, "story": "%s", "outcome": "%s", "changed": %s, "reason": "%s"}\n' \
        "$1" "$(json_str "$story")" "$(json_str "$outcome")" "$3" "${2:-}"
    [ "$1" = "true" ] && exit 0 || exit 1
}

[ -n "$story" ] || emit false no_story_argument false
[ -n "$outcome" ] || emit false no_outcome_argument false
[ -f "$story" ] || emit false story_not_found false

# ONE LINE, because the reader reads one. A multi-line outcome would round-trip as something
# the oracle cannot parse, and silently: it would simply not match, and the claim would read
# `queue_drained` — the exact silence this section exists to end.
# `wc -l` counts newlines, so a single line with no trailing newline is 0. A `case` against
# `$(printf '\n')` cannot do this: command substitution strips trailing newlines, so the
# pattern collapses to the empty string and matches everything.
[ "$(printf '%s' "$outcome" | wc -l | tr -d ' ')" = "0" ] || emit false outcome_not_one_line false

# The section is always heading, blank, value — so the value is two lines after the heading.
existing=$(sed -n '/^## Merge Outcome$/{n;n;p;}' "$story" || true)

if [ "$existing" = "$outcome" ]; then
    emit true "" false
fi

tmp=$(mktemp)
# Drop any previous section (it runs to end of file — the section is always written last), then
# append the current answer.
sed '/^## Merge Outcome$/,$d' "$story" > "$tmp"
# Exactly one blank line before the heading, whatever the body ended with.
printf '%s' "$(cat "$tmp")" > "${tmp}.trimmed"
mv "${tmp}.trimmed" "$tmp"
{
    echo ""
    echo ""
    echo "## Merge Outcome"
    echo ""
    echo "$outcome"
} >> "$tmp"
mv "$tmp" "$story"

emit true "" true
