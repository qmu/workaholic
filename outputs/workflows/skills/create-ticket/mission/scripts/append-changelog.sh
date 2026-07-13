#!/bin/sh -eu
# Append one dated line to a mission's ## Changelog. Append-only and idempotent:
# the (event, artifact) pair is the stable event id, so re-running for the same
# event (retries, re-reports) never duplicates a line. The mission file is
# git-staged so the calling seam's commit carries the change.
#
# This is the single writer of mission changelog lines — every workflow seam
# (drive archive, ship extract, report verdicts/story) calls it rather than
# hand-editing mission.md, so the format and idempotency rule live in one place.
#
# Usage: append-changelog.sh <mission-slug-or-file> <event> <artifact-filename> [date]
#   date defaults to today (YYYY-MM-DD); pass it explicitly for deterministic tests.
# Output: JSON {appended, path[, reason]}

set -eu

ARG="${1:-}"
EVENT="${2:-}"
ARTIFACT="${3:-}"
DATE="${4:-$(date +%Y-%m-%d)}"

if [ -z "$ARG" ] || [ -z "$EVENT" ] || [ -z "$ARTIFACT" ]; then
    echo '{"appended": false, "reason": "missing_args"}' >&2
    exit 1
fi

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
missions_migrate_layout
FILE=$(mission_resolve "$ARG")
[ -f "$FILE" ] || { printf '{"appended": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

# Stable event id = "<event> — <artifact>" (date excluded, so a re-run on any day
# is a no-op). If a changelog line already records it, append nothing.
KEY="${EVENT} — ${ARTIFACT}"
if grep -Fq -- "$KEY" "$FILE"; then
    printf '{"appended": false, "reason": "duplicate", "path": "%s"}\n' "$FILE"
    exit 0
fi

NEWLINE="- ${DATE} — ${EVENT} — ${ARTIFACT}"
TMP="${FILE}.$$.tmp"

# Insert the entry as the last line of the ## Changelog section (before the next
# "## " heading, or at EOF), so entries accumulate oldest-first, newest-last.
awk -v line="$NEWLINE" '
    /^## / {
        if (in_cl && !done) { print line; done = 1; in_cl = 0 }
        if ($0 ~ /^##[ \t]+Changelog[ \t]*$/) { in_cl = 1 }
    }
    { print }
    END { if (in_cl && !done) print line }
' "$FILE" > "$TMP"

# A missing ## Changelog section leaves the file unchanged — report it rather than
# silently dropping the event.
if ! grep -Fq -- "$NEWLINE" "$TMP"; then
    rm -f "$TMP"
    printf '{"appended": false, "reason": "no_changelog_section", "path": "%s"}\n' "$FILE" >&2
    exit 1
fi

mv "$TMP" "$FILE"
git add "$FILE" 2>/dev/null || true
printf '{"appended": true, "path": "%s"}\n' "$FILE"
