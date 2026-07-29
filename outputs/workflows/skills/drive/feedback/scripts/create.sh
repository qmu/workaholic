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
# Usage: printf '%s\n' "<body>" | create.sh "<title>" <kind> <source> [supersedes-filename]
#   kind:   insight | instruction | concern | material | answer
#   source: meeting | slack | discussion
# Output: JSON {created, path[, reason]}

set -eu

TITLE="${1:-}"
KIND="${2:-}"
SOURCE="${3:-}"
SUPERSEDES="${4:-}"

[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }

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
META=$(sh "${SCRIPT_DIR}/../../gather/scripts//ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')

# Timestamp prefix: the first 14 digits of created_at (YYYYMMDDHHMMSS).
TS=$(printf '%s' "$CREATED_AT" | tr -dc '0-9' | cut -c1-14)
[ -n "$TS" ] || { echo '{"created": false, "reason": "no_timestamp"}'; exit 1; }

# Slug rule lives in mission/scripts/slug.sh (the single source), reused verbatim.
SLUG=$(sh "${SCRIPT_DIR}/../../mission/scripts//slug.sh" "$TITLE")
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
    printf 'created_at: %s\n' "$CREATED_AT"
    printf 'author: %s\n' "$AUTHOR"
    printf 'supersedes: %s\n' "$SUPERSEDES"
    printf -- '---\n'
    printf '\n# %s\n\n' "$TITLE"
    printf '%s\n' "$BODY"
} > "$FILE"

# Refresh the OKF bundle indexes so the registering commit ships a fresh hierarchy
# (best-effort: an index problem must not block feedback capture).
sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true

printf '{"created": true, "path": "%s"}\n' "$FILE"
