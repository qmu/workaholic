#!/bin/sh
# The one derivation of a question's identity in the tick log. Sourced, never executed.
#
# WHY IT IS A LIBRARY (2026-08-23). Three scripts now key on the same identity — the gate
# (`ask-question.sh`), the writer of an answer (`record-answer.sh`) and the reader of a
# question's state (`question-state.sh`) — and a question whose id differed between them
# would silently be a different question: an answer filed under one id would never clear a
# gate reading another, which is the exact failure mode this mission exists to end. One
# copy, sourced, so they cannot drift.
#
# THE ID IS INJECTIVE ON THE KEY, which the slug alone was not: it lowercases, collapses
# every non-alphanumeric run and truncates, so two long keys sharing a prefix produced one
# id — and once the gate reads the id, a collision SUPPRESSES a question rather than merely
# miscounting one. A short digest of the whole key is appended so that cannot happen.
#
# Usage: . <this file>; slug=$(question_slug "<key>")
#   `human-checkin-ask-<slug>`      the question was asked
#   `human-checkin-answered-<slug>` a person answered it, and the summary carries their words

question_slug() {
    _qs_key="${1:-}"
    _qs_short=$(printf '%s' "$_qs_key" | tr 'A-Z' 'a-z' \
        | sed 's/[^a-z0-9]\{1,\}/-/g; s/^-//; s/-$//' | cut -c1-24)
    [ -n "$_qs_short" ] || _qs_short=q
    _qs_digest=$(printf '%s' "$_qs_key" | cksum | cut -d' ' -f1)
    printf '%s-%s' "$_qs_short" "$_qs_digest"
}
