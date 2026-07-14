#!/bin/sh -eu
# Summarize the current user's assigned ACTIVE missions (read-only).
#
# "Assigned to me" = the mission's `assignee` frontmatter matches the current
# `git config user.email` — the same gate the mission lens uses. Only `active`
# missions are reported. Progress is computed on demand via progress.sh and the
# next step via next-acceptance.sh (never a stored number). Creates nothing.
#
# Usage: summary.sh
# Output: JSON array [{slug, title, checked, total, next, path}], sorted by slug;
#         [] when no active mission is assigned to the current user.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT=".workaholic/missions"

EMAIL=$(git config user.email 2>/dev/null || true)

if [ ! -d "$ROOT" ] || [ -z "$EMAIL" ]; then
    echo '[]'
    exit 0
fi

# Heal any legacy flat layout first so active missions surface under active/.
. "${SCRIPT_DIR}/lib/resolve.sh"
missions_migrate_layout

# JSON-escape a value (backslash and double-quote only; titles are plain text).
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Read a frontmatter field's value ("" when absent).
fm_field() {
    grep -m1 "^$2:" "$1" 2>/dev/null | sed -e "s/^$2:[ \t]*//" || true
}

DIRS=$(find "$ROOT/active" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort || true)

OUT="["
FIRST=1
for d in $DIRS; do
    f="$d/mission.md"
    [ -f "$f" ] || continue
    [ "$(fm_field "$f" status)" = "active" ] || continue
    [ "$(fm_field "$f" assignee)" = "$EMAIL" ] || continue
    slug=$(basename "$d")
    title=$(json_escape "$(fm_field "$f" title)")
    prog=$(sh "${SCRIPT_DIR}/progress.sh" "$f")
    checked=$(printf '%s' "$prog" | sed -e 's/.*"checked": *//' -e 's/[,}].*//')
    total=$(printf '%s' "$prog" | sed -e 's/.*"total": *//' -e 's/[,}].*//')
    next=$(json_escape "$(sh "${SCRIPT_DIR}/next-acceptance.sh" "$f")")
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"slug\":\"${slug}\",\"title\":\"${title}\",\"checked\":${checked},\"total\":${total},\"next\":\"${next}\",\"path\":\"${f}\"}"
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
