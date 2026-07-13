#!/bin/sh -eu
# End a mission: flip its `status` frontmatter to achieved or abandoned, record
# the transition as an append-only ## Changelog line (via append-changelog.sh,
# the single changelog writer -- the history survives the close), and move the
# mission dir from active/ into archive/. This is the ONLY sanctioned way to end
# a mission -- never hand-edit `status:` or `mv` a mission dir.
#
# Idempotent: closing an already-archived mission with the same status is a
# no-op ({closed: false, reason: "already_closed"}); the changelog append is
# idempotent on its (event, artifact) pair. Re-closing with the OTHER status
# (achieved -> abandoned or back) flips the status and appends its own line,
# preserving the full transition history.
#
# Usage: close.sh <mission-slug-or-file> <achieved|abandoned> [date]
#   date defaults to today (YYYY-MM-DD); pass it explicitly for deterministic tests.
# Output: JSON {closed, slug, status, path[, reason]}

set -eu

ARG="${1:-}"
TARGET="${2:-}"
DATE="${3:-}"

if [ -z "$ARG" ] || [ -z "$TARGET" ]; then
    echo '{"closed": false, "reason": "missing_args"}' >&2
    exit 1
fi
case "$TARGET" in
    achieved|abandoned) : ;;
    *) printf '{"closed": false, "reason": "invalid_status", "status": "%s"}\n' "$TARGET" >&2; exit 1 ;;
esac

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
missions_migrate_layout
FILE=$(mission_resolve "$ARG")
[ -f "$FILE" ] || { printf '{"closed": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

MISSION_DIR=$(dirname "$FILE")
SLUG=$(basename "$MISSION_DIR")
AREA=$(basename "$(dirname "$MISSION_DIR")")
CURRENT=$(grep -m1 '^status:' "$FILE" 2>/dev/null | sed -e 's/^status:[ \t]*//' -e 's/[ \t]*$//' || true)

if [ "$AREA" = "archive" ] && [ "$CURRENT" = "$TARGET" ]; then
    printf '{"closed": false, "reason": "already_closed", "slug": "%s", "status": "%s", "path": "%s"}\n' "$SLUG" "$TARGET" "$FILE"
    exit 0
fi

# Flip the status field inside the frontmatter block only (a `status:` in the
# body -- e.g. inside a code fence -- is never touched).
if [ "$CURRENT" != "$TARGET" ]; then
    TMP="${FILE}.$$.tmp"
    awk -v new="$TARGET" '
        NR == 1 && $0 == "---" { in_fm = 1; print; next }
        in_fm && /^---[ \t]*$/ { in_fm = 0; print; next }
        in_fm && /^status:/ { print "status: " new; next }
        { print }
    ' "$FILE" > "$TMP"
    mv "$TMP" "$FILE"
fi

# Record the transition in the append-only changelog (idempotent on the
# (event, artifact) pair; the artifact is the mission file itself).
if [ -n "$DATE" ]; then
    sh "${SCRIPT_DIR}/append-changelog.sh" "$FILE" "mission ${TARGET}" "mission.md" "$DATE" >/dev/null
else
    sh "${SCRIPT_DIR}/append-changelog.sh" "$FILE" "mission ${TARGET}" "mission.md" >/dev/null
fi

# Move the mission into the archive/ area (unless already there). git mv keeps
# history; plain mv + git add covers an untracked mission.
if [ "$AREA" != "archive" ]; then
    MROOT=$(dirname "$MISSION_DIR")
    [ "$AREA" = "active" ] && MROOT=$(dirname "$MROOT")
    DEST="${MROOT}/archive/${SLUG}"
    mkdir -p "${MROOT}/archive"
    # A same-slug dir already in archive/ is a conflicted state a human must
    # resolve -- keep the mission where it is rather than nesting dirs.
    if [ -e "$DEST" ]; then
        printf '{"closed": true, "slug": "%s", "status": "%s", "path": "%s", "reason": "archive_slug_conflict"}\n' "$SLUG" "$TARGET" "$FILE"
        exit 0
    fi
    if git mv "$MISSION_DIR" "$DEST" >/dev/null 2>&1; then
        :
    else
        mv "$MISSION_DIR" "$DEST"
        git add -A "$MROOT" >/dev/null 2>&1 || true
    fi
    FILE="${DEST}/mission.md"
fi

# Refresh the OKF bundle indexes so the close commit ships a fresh hierarchy
# (best-effort: an index problem must not block the close).
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true

printf '{"closed": true, "slug": "%s", "status": "%s", "path": "%s"}\n' "$SLUG" "$TARGET" "$FILE"
