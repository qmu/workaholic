#!/bin/sh -eu
# Prepare a /carry checkpoint. Emits the resumption-ticket path and the
# frontmatter metadata a fresh /drive session needs, plus whether a trip is in
# progress so the skill can also checkpoint the trip's plan.md / event-log.md.
#
# The skill authors the resumption ticket's prose from conversation context;
# this script owns only the deterministic parts (dynamic metadata, the
# per-user todo path, trip detection) so no conditional shell lives in markdown.
#
# Usage: carry-checkpoint.sh <slug>
#   <slug> — short kebab-case description for the resumption ticket filename.
# Output: JSON { created_at, author, filename_timestamp, user_slug, slug,
#                ticket_path, trips_present, trips }

set -eu

SLUG="${1:-}"
if [ -z "$SLUG" ]; then
    echo 'usage: carry-checkpoint.sh <slug>' >&2
    exit 1
fi

SCRIPT_DIR=$(dirname "$0")

CREATED_AT=$(date -Iseconds)
AUTHOR=$(git config user.email || true)
[ -n "$AUTHOR" ] || { echo 'git user.email is not set; run: git config user.email you@example.com' >&2; exit 1; }
FILENAME_TS=$(date +%Y%m%d%H%M%S)
USER_SLUG=$(sh "${SCRIPT_DIR}/../../gather/scripts/user-slug.sh")

TICKET_PATH=".workaholic/tickets/todo/${USER_SLUG}/${FILENAME_TS}-${SLUG}.md"

TRIPS_DIR=".workaholic/trips"
TRIPS_JSON="[]"
TRIPS_PRESENT=false
if [ -d "$TRIPS_DIR" ]; then
    items=""
    for d in "$TRIPS_DIR"/*/; do
        [ -d "$d" ] || continue
        name=$(basename "$d")
        items="${items},\"${name}\""
    done
    if [ -n "$items" ]; then
        TRIPS_JSON="[${items#,}]"
        TRIPS_PRESENT=true
    fi
fi

cat <<EOF
{
  "created_at": "${CREATED_AT}",
  "author": "${AUTHOR}",
  "filename_timestamp": "${FILENAME_TS}",
  "user_slug": "${USER_SLUG}",
  "slug": "${SLUG}",
  "ticket_path": "${TICKET_PATH}",
  "trips_present": ${TRIPS_PRESENT},
  "trips": ${TRIPS_JSON}
}
EOF
