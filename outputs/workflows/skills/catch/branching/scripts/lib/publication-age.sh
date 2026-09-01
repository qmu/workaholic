#!/bin/sh
# HOW OLD A PUBLICATION IS — ONE DERIVATION (2026-09-01, ticket
# `20260901062000-check-a-stranded-proposal-is-still-worth-landing.md`).
#
# Three callers need the age of one pull request and must never disagree about it:
#
#   branching/scripts/publication-effect.sh           reports `age_hours` for an
#                                                     operator-facing publication.
#   branching/scripts/list-stranded-publications.sh   reports `age_hours` beside each
#                                                     stranded publication's class.
#   branching/scripts/settle-stranded-publication.sh  re-derives it at the moment of the
#                                                     act, as it re-derives the class.
#
# WHY AN AGE IS WORTH DERIVING AT ALL. `publish-tree-pr.sh` auto-merges on opening, so a
# proposal is normally written and landed minutes apart and its age says nothing. Only a
# publication the transport refused stays open long enough to go stale — and measured on
# 2026-09-01, five of six open publications were `clean`, the oldest six days old, and
# landing them queued roughly fifteen tickets for work the loop had already finished.
#
# IT IS EVIDENCE, NEVER A GATE. Nothing here refuses, holds, drops or delays a publication
# on its age. The act stays unconditional in both directions, deliberately: an age
# threshold on the act would strand exactly the publications the `clean` widening exists to
# deliver, and this repository has paid repeatedly for a reading that stops something and
# tells nobody. What the age earns is that a person is TOLD — the run report names it, and
# `/moderate` asks about a publication that is still open and already stale.
#
# THE UNIT IS HOURS, and a caller wanting days divides. Hours is the finer of the two and
# the one `publication-effect.sh` already reported, so adopting it costs that caller
# nothing; deriving days here and hours there is how two readings of one fact start
# disagreeing at the boundary.
#
# AN UNPARSEABLE OR ABSENT TIMESTAMP ANSWERS EMPTY, never `0`. Zero reads as *opened this
# second*, which is the one answer that would make a stale publication look fresh — the
# same reasoning `cadence-state.sh` records for its own null age. A caller renders an empty
# answer as JSON `null` and says the age is unreadable rather than reporting a number it
# could not establish.
#
# Usage, from a branching script with LIB its own scripts/lib dir:
#     . "${LIB}/publication-age.sh"
#     hours=$(publication_age_hours "$created_at")

# publication_age_hours <created_at-ISO8601>
# Echoes whole hours since <created_at>, or nothing when it cannot be read.
publication_age_hours() {
    _pa_created="${1:-}"
    [ -n "$_pa_created" ] || return 0
    _pa_epoch="$(date -u -d "$_pa_created" +%s 2>/dev/null \
        || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$_pa_created" +%s 2>/dev/null \
        || printf '')"
    [ -n "$_pa_epoch" ] || return 0
    _pa_now="$(date -u +%s)"
    _pa_hours=$(( (_pa_now - _pa_epoch) / 3600 ))
    [ "$_pa_hours" -ge 0 ] || _pa_hours=0
    printf '%s' "$_pa_hours"
}

# publication_age_json <created_at-ISO8601>
# The same reading, rendered for a JSON field: the number, or the literal `null`.
publication_age_json() {
    _paj="$(publication_age_hours "${1:-}")"
    if [ -n "$_paj" ]; then printf '%s' "$_paj"; else printf 'null'; fi
}
