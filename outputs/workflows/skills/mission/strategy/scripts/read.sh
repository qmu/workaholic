#!/bin/sh -eu
# Read one strategy: its fields plus the path to the file, so a caller can print
# the prose itself rather than have this script re-encode it. Pure read.
#
# Usage: read.sh <slug> [workaholic-root]
# Output: JSON {found, path, slug, title, status, target_date, assignees, feedback}

set -eu

SLUG="${1:-}"
ROOT="${2:-.workaholic}"
[ -n "$SLUG" ] || { echo '{"found": false, "reason": "no_slug"}'; exit 1; }

FILE="${ROOT}/strategies/${SLUG}.md"
if [ ! -f "$FILE" ]; then
    printf '{"found": false, "reason": "not_found", "path": "%s"}\n' "$FILE"
    exit 1
fi

fm() {
    awk -v key="$1" '
        NR==1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        $0 ~ "^" key ":" { sub("^" key ":[ \t]*", ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$FILE" 2>/dev/null || true
}

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

printf '{"found": true, "path": "%s", "slug": "%s", "title": "%s", "status": "%s", "target_date": "%s", "assignees": "%s", "feedback": "%s"}\n' \
    "$FILE" \
    "$(json_escape "$SLUG")" \
    "$(json_escape "$(fm title)")" \
    "$(json_escape "$(fm status)")" \
    "$(json_escape "$(fm target_date)")" \
    "$(json_escape "$(fm assignees | sed -e 's/^\[//' -e 's/\]$//')")" \
    "$(json_escape "$(fm feedback | sed -e 's/^\[//' -e 's/\]$//')")"
