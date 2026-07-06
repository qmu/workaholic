#!/bin/sh -eu
# List every mission with its status and computed progress (checked/total).
# Progress is derived per mission via progress.sh, never read from a stored number.
#
# Usage: list.sh
# Output: JSON array [{slug, title, status, checked, total}], sorted by slug.
#         Emits [] when there are no missions.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT=".workaholic/missions"

if [ ! -d "$ROOT" ]; then
    echo '[]'
    exit 0
fi

# JSON-escape a value (backslash and double-quote only; titles are plain text).
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Read a frontmatter field's value ("" when absent).
fm_field() {
    grep -m1 "^$2:" "$1" 2>/dev/null | sed -e "s/^$2:[ \t]*//" || true
}

OUT="["
FIRST=1
for d in $(find "$ROOT" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort); do
    f="$d/mission.md"
    [ -f "$f" ] || continue
    slug=$(basename "$d")
    title=$(json_escape "$(fm_field "$f" title)")
    status=$(json_escape "$(fm_field "$f" status)")
    prog=$(sh "${SCRIPT_DIR}/progress.sh" "$f")
    checked=$(printf '%s' "$prog" | sed -e 's/.*"checked": *//' -e 's/[,}].*//')
    total=$(printf '%s' "$prog" | sed -e 's/.*"total": *//' -e 's/[,}].*//')
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"slug\":\"${slug}\",\"title\":\"${title}\",\"status\":\"${status}\",\"checked\":${checked},\"total\":${total}}"
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
