#!/bin/sh -eu
# End a strategy: the ONLY writer of an end state, exactly as mission/close.sh is
# for missions. A closed strategy does NOT move — there is no archive area for
# this artifact; the file stays put and its `status` says what happened, because a
# strategy is small enough that its whole history is the one file.
#
# Idempotent: closing an already-closed strategy to the same state is a no-op that
# reports success. Re-opening is NOT offered — a decision that was ended and is
# being pursued again is a new strategy with its own dates, not a reverted field.
#
# Usage: close.sh <slug> achieved|abandoned [workaholic-root]
# Output: JSON {closed, path, status[, reason]}

set -eu

SLUG="${1:-}"
STATUS="${2:-}"
ROOT="${3:-.workaholic}"

[ -n "$SLUG" ] || { echo '{"closed": false, "reason": "no_slug"}'; exit 1; }
case "$STATUS" in
    achieved|abandoned) : ;;
    *) echo '{"closed": false, "reason": "bad_status"}'; exit 1 ;;
esac

FILE="${ROOT}/strategies/${SLUG}.md"
if [ ! -f "$FILE" ]; then
    printf '{"closed": false, "reason": "not_found", "path": "%s"}\n' "$FILE"
    exit 1
fi

CURRENT=$(awk '
    NR==1 { if ($0 != "---") exit; next }
    /^---[ \t]*$/ { exit }
    /^status:/ { sub(/^status:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
' "$FILE" 2>/dev/null || true)

if [ "$CURRENT" = "$STATUS" ]; then
    printf '{"closed": true, "path": "%s", "status": "%s", "reason": "already"}\n' "$FILE" "$STATUS"
    exit 0
fi

case "$CURRENT" in
    achieved|abandoned)
        printf '{"closed": false, "reason": "already_ended", "path": "%s", "status": "%s"}\n' "$FILE" "$CURRENT"
        exit 1
        ;;
esac

TMP="${FILE}.tmp.$$"
awk -v new="$STATUS" '
    BEGIN { infm = 0; done = 0 }
    NR==1 && $0 == "---" { infm = 1; print; next }
    infm && /^---[ \t]*$/ { infm = 0; print; next }
    infm && /^status:/ && !done { print "status: " new; done = 1; next }
    { print }
' "$FILE" > "$TMP"
mv "$TMP" "$FILE"

SCRIPT_DIR=$(dirname "$0")
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true
git add "$FILE" 2>/dev/null || true

printf '{"closed": true, "path": "%s", "status": "%s"}\n' "$FILE" "$STATUS"
