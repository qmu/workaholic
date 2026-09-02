#!/bin/sh -eu
# THE SINGLE READER OF WHETHER A PERSON WANTED THIS.
#
#   ask-origin.sh <record-path>      # a feedback record on disk
#   ask-origin.sh < <the ask body>   # a GitHub issue body, which has no file to name
#
# Output: one JSON line, and exit 0 in EVERY case, including every degradation:
#   {"origin": "human"|"machine"|"unreadable", "reason": "",
#    "subject_kind": "", "subject_identity": "", "author": ""}
#
# ═══ WHY THIS EXISTS ═════════════════════════════════════════════════════════════════
# MEASURED 2026-09-02: five consecutive `[FB]` roots in one day that no human wrote — each
# a record a routine session authored about the loop's own apparatus, each proposed,
# ticketed, implemented and merged by the next ticks, each link refining the one before it
# — until the operator abandoned the direction mid-drive and reported the whole day as
# waste, with real development stopped throughout. Every gate in `/specificate` and
# `/propose` held. Not one of them asks **who wanted this**.
#
# NO NEW FIELD, AND THAT IS THE POINT. The repository already carries the three axes the
# answer is made of (`workaholic:feedback`, *Choosing the subject*): `subject:` is **who
# formed the opinion**, `author:` is the git identity that ran the capture, `source:` is
# the channel it arrived through. They disagree routinely — an Observer AI reporting
# through Slack has all three different — and a record whose subject kind is `observer_ai`
# is, by the schema's own definition, a machine's opinion. A fourth field would be a second
# place for one fact to drift.
#
# IT ANSWERS *WHO*, NEVER *ABOUT WHAT*. The operator's rule has two halves — *a routine
# wrote it* AND *its subject is the loop's own apparatus* — and only the first is
# mechanical. A script that guessed the second would refuse the real asks about the loop
# that people write, which is most of this repository's inbox. The consuming bar applies
# the second half as the run's own judgement, in words, where a person can argue with it.
#
# `unreadable` IS A REAL THIRD VALUE AND NEVER COLLAPSES. `validate-feedback.sh` floors the
# subject on NEW writes and grandfathers everything older, so a record with no `subject:` is
# ordinary history — it is `unreadable:no_subject`, not `human` and not `machine`, and what
# to do about it belongs to the consumer. `other` is the same shape for a different reason:
# the axis was read and does not decide, so it says so rather than picking a side.
#
# THE AUTHOR IS EVIDENCE, NEVER THE ANSWER. A routine session's capture carries its own
# author, so keying on it would mark a human's ask captured by a routine as machine-written
# — which is exactly the inbound sweep's main path. It rides the answer so a consumer can
# see what the reading rested on; it decides nothing.

set -eu

SRC="${1:-}"
BODY=""
if [ -n "$SRC" ]; then
    if [ ! -f "$SRC" ]; then
        printf '{"origin": "unreadable", "reason": "not_found", "subject_kind": "", "subject_identity": "", "author": ""}\n'
        exit 0
    fi
    BODY=$(cat -- "$SRC" 2>/dev/null || printf '')
else
    BODY=$(cat 2>/dev/null || printf '')
fi

# The frontmatter block, when there is one. A GitHub issue body carries the same three
# lines as visible text instead (`open-issue.sh` composes `kind: … / source: … /
# subject: …`), so the field is read line-wise rather than from a YAML block — the two
# surfaces of one record must not need two parsers.
_field() { # $1 = field name
    printf '%s\n' "$BODY" \
        | sed -n "s/^[[:space:]]*$1:[[:space:]]*//p" \
        | sed -n '1p' \
        | sed 's/[[:space:]]*$//'
}
# `open-issue.sh` writes the three axes on ONE line separated by ` / `, so a bare
# line-start match would take `person:a@qmu.jp` plus everything after it.
_inline_subject() {
    printf '%s\n' "$BODY" \
        | sed -n 's/.*[[:space:]]subject:[[:space:]]*\([^/]*\).*/\1/p' \
        | sed -n '1p' \
        | sed 's/[[:space:]]*$//'
}

SUBJECT=$(_field subject)
[ -n "$SUBJECT" ] || SUBJECT=$(_inline_subject)
SUBJECT=$(printf '%s' "$SUBJECT" | sed 's#[[:space:]]*/.*$##' | sed 's/[[:space:]]*$//')
AUTHOR=$(_field author)

KIND="${SUBJECT%%:*}"
IDENTITY=""
case "$SUBJECT" in *:*) IDENTITY="${SUBJECT#*:}" ;; esac

_emit() { # $1 = origin, $2 = reason
    printf '{"origin": "%s", "reason": "%s", "subject_kind": "%s", "subject_identity": "%s", "author": "%s"}\n' \
        "$1" "$2" "$KIND" "$IDENTITY" "$AUTHOR"
    exit 0
}

if [ -z "$(printf '%s' "$BODY" | tr -d '[:space:]')" ]; then
    KIND=""; IDENTITY=""; AUTHOR=""
    _emit unreadable empty
fi
if [ -z "$(printf '%s' "$SUBJECT" | tr -d '[:space:]')" ]; then
    KIND=""; IDENTITY=""
    _emit unreadable no_subject
fi

case "$KIND" in
    person|meeting|customer|team) _emit human "" ;;
    observer_ai)                  _emit machine "" ;;
    # DECLARED AND INDECISIVE. `other` is inside the closed set, so nothing is malformed —
    # the axis simply does not say whose opinion this is, and answering `human` would let
    # the loop's own record through while answering `machine` would refuse a real one.
    other)                        _emit unreadable subject_kind_other ;;
    *)                            _emit unreadable "bad_subject_kind" ;;
esac
