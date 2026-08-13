#!/bin/sh -eu
# Register one feedback: an immutable record of inbound project context, written to
# .workaholic/feedbacks/<YYYYMMDDHHMMSS>-<slug>.md (flat area — records never move).
# The body arrives on stdin, in the contributor's own words; frontmatter is stamped
# from the gather skill; the slug rule is REUSED from mission/scripts/slug.sh (the
# single slug source) and the timestamp prefix comes from created_at, so filenames
# sort chronologically and never collide. Refuses an existing filename and unknown
# kind/source values. Refreshes the OKF bundle indexes and git-stages the file.
#
# A feedback has NO status field and is never edited after this write — resolution
# or mootness is a NEW entry naming the old one via the optional supersedes
# argument (see feedback/SKILL.md, Immutability).
#
# THREE axes are recorded and they answer three different questions, so none of
# them substitutes for another (feedback/reference/schema.md, Field semantics):
#   subject = WHOSE opinion this is   (a person, a meeting, an observer AI, ...)
#   source  = WHICH CHANNEL it arrived through (meeting | slack | discussion | development)
#   author  = WHO RAN THE CAPTURE     (a git identity; under a routine, the runner)
# `subject` is REQUIRED and is never defaulted — least of all to the author. A
# routine writes most of this stream, so a defaulted subject would say every
# opinion in the project is the runner's, which is the exact failure `assignees`
# had before P6. A caller that does not know the subject must find it, not guess.
#
# Usage: printf '%s\n' "<body>" | create.sh --subject <subject> "<title>" <kind> <source> [supersedes-filename]
#   subject: <kind>[:<identity>]; kind is the closed set
#            person | meeting | observer_ai | customer | team | other
#            and the identity after the colon is free text ("person:a@qmu.jp",
#            "meeting:2026-08-13 planning", "observer_ai:[Implement] routine")
#   kind:    insight | instruction | concern | material | answer
#   source:  meeting | slack | discussion | development
# Output: JSON {created, path[, reason]}
#
# `--subject` is an OPTION, deliberately: the positional contract every caller
# already uses is left exactly where it was, so adding the axis moved no argument.

set -eu

SUBJECT=""
if [ "${1:-}" = "--subject" ]; then
    SUBJECT="${2:-}"
    shift 2
fi

TITLE="${1:-}"
KIND="${2:-}"
SOURCE="${3:-}"
SUPERSEDES="${4:-}"

[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }

[ -n "$(printf '%s' "$SUBJECT" | tr -d '[:space:]')" ] || {
    echo '{"created": false, "reason": "no_subject"}'; exit 1; }
case "${SUBJECT%%:*}" in
    person|meeting|observer_ai|customer|team|other) : ;;
    *) echo '{"created": false, "reason": "bad_subject_kind"}'; exit 1 ;;
esac

case "$KIND" in
    insight|instruction|concern|material|answer) : ;;
    *) echo '{"created": false, "reason": "bad_kind"}'; exit 1 ;;
esac
case "$SOURCE" in
    meeting|slack|discussion) : ;;
    *) echo '{"created": false, "reason": "bad_source"}'; exit 1 ;;
esac

# Body from stdin. An empty body is refused: a feedback with no content records
# nothing — the record IS the prose.
BODY=$(cat)
[ -n "$(printf '%s' "$BODY" | tr -d '[:space:]')" ] || { echo '{"created": false, "reason": "empty_body"}'; exit 1; }

SCRIPT_DIR=$(dirname "$0")

# created_at / author from the single canonical gather script (one line per field).
META=$(sh "${SCRIPT_DIR}/../../gather/scripts/ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')

# Timestamp prefix: the first 14 digits of created_at (YYYYMMDDHHMMSS).
TS=$(printf '%s' "$CREATED_AT" | tr -dc '0-9' | cut -c1-14)
[ -n "$TS" ] || { echo '{"created": false, "reason": "no_timestamp"}'; exit 1; }

# Slug rule lives in mission/scripts/slug.sh (the single source), reused verbatim.
SLUG=$(sh "${SCRIPT_DIR}/../../mission/scripts/slug.sh" "$TITLE")
[ -n "$SLUG" ] || { echo '{"created": false, "reason": "empty_slug"}'; exit 1; }

DIR=".workaholic/feedbacks"
FILE="${DIR}/${TS}-${SLUG}.md"

if [ -e "$FILE" ]; then
    printf '{"created": false, "reason": "exists", "path": "%s"}\n' "$FILE"
    exit 1
fi

mkdir -p "$DIR"
{
    printf -- '---\n'
    printf 'type: Feedback\n'
    printf 'title: %s\n' "$TITLE"
    printf 'kind: %s\n' "$KIND"
    printf 'source: %s\n' "$SOURCE"
    printf 'subject: %s\n' "$SUBJECT"
    printf 'created_at: %s\n' "$CREATED_AT"
    printf 'author: %s\n' "$AUTHOR"
    printf 'supersedes: %s\n' "$SUPERSEDES"
    printf -- '---\n'
    printf '\n# %s\n\n' "$TITLE"
    printf '%s\n' "$BODY"
} > "$FILE"

# Refresh the OKF bundle indexes so the registering commit ships a fresh hierarchy
# (best-effort: an index problem must not block feedback capture).
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true

printf '{"created": true, "path": "%s"}\n' "$FILE"
