#!/bin/sh -eu
# Retire a strategy: flip its `status` frontmatter to `retired`, record the transition
# as an append-only ## Changelog line, and move the strategy dir from active/ into
# archive/. This is the close.sh analogue for strategies, minus all the mission
# machinery -- there are no worktrees, no successors, no carry semantics.
#
# Retirement is RARE and simple. A strategy whose direction CHANGED is rewritten in
# place (its changelog records the turn); only a strategy that is genuinely OVER is
# retired. There is no "carried" outcome and no acceptance list to reconcile.
#
# Idempotent: retiring an already-archived strategy is a no-op; the changelog append is
# idempotent on its (event, artifact) pair.
#
# Usage: retire.sh <strategy-slug-or-file> [date]
#   date defaults to today (YYYY-MM-DD); pass it explicitly for deterministic tests.
# Output: JSON {retired, slug, status, path[, reason]}

set -eu

ARG="${1:-}"
DATE="${2:-}"

[ -n "$ARG" ] || { echo '{"retired": false, "reason": "missing_args"}' >&2; exit 1; }

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
ROOT=$(strategies_root_for_arg "$ARG")
FILE=$(strategy_resolve "$ROOT" "$ARG")
[ -f "$FILE" ] || { printf '{"retired": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

STRATEGY_DIR=$(dirname "$FILE")
SLUG=$(basename "$STRATEGY_DIR")
AREA=$(basename "$(dirname "$STRATEGY_DIR")")
CURRENT=$(grep -m1 '^status:' "$FILE" 2>/dev/null | sed -e 's/^status:[ \t]*//' -e 's/[ \t]*$//' || true)

if [ "$AREA" = "archive" ] && [ "$CURRENT" = "retired" ]; then
    printf '{"retired": false, "reason": "already_retired", "slug": "%s", "status": "retired", "path": "%s"}\n' "$SLUG" "$FILE"
    exit 0
fi

# Flip the status field inside the frontmatter block only.
if [ "$CURRENT" != "retired" ]; then
    TMP="${FILE}.$$.tmp"
    awk '
        NR == 1 && $0 == "---" { in_fm = 1; print; next }
        in_fm && /^---[ \t]*$/ { in_fm = 0; print; next }
        in_fm && /^status:/ { print "status: retired"; next }
        { print }
    ' "$FILE" > "$TMP"
    mv "$TMP" "$FILE"
fi

# Record the transition via the single changelog writer (mission/append-changelog.sh,
# which takes any artifact path and owns the format + idempotency). The strategy.md
# carries the same ## Changelog shape as a mission, so the writer works verbatim.
if [ -n "$DATE" ]; then
    sh "${SCRIPT_DIR}/../../mission/scripts/append-changelog.sh" "$FILE" "strategy retired" "strategy.md" "$DATE" >/dev/null 2>&1 || true
else
    sh "${SCRIPT_DIR}/../../mission/scripts/append-changelog.sh" "$FILE" "strategy retired" "strategy.md" >/dev/null 2>&1 || true
fi

# Move the strategy into the archive/ area (unless already there).
if [ "$AREA" != "archive" ]; then
    SROOT=$(dirname "$STRATEGY_DIR")
    [ "$AREA" = "active" ] && SROOT=$(dirname "$SROOT")
    DEST="${SROOT}/archive/${SLUG}"
    mkdir -p "${SROOT}/archive"
    if [ -e "$DEST" ]; then
        printf '{"retired": true, "slug": "%s", "status": "retired", "path": "%s", "reason": "archive_slug_conflict"}\n' "$SLUG" "$FILE"
        exit 0
    fi
    if git mv "$STRATEGY_DIR" "$DEST" >/dev/null 2>&1; then
        :
    else
        mv "$STRATEGY_DIR" "$DEST"
        git add -A "$SROOT" >/dev/null 2>&1 || true
    fi
    FILE="${DEST}/strategy.md"
fi

# Refresh the OKF bundle indexes so the retire commit ships a fresh hierarchy.
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true

printf '{"retired": true, "slug": "%s", "status": "retired", "path": "%s"}\n' "$SLUG" "$FILE"
