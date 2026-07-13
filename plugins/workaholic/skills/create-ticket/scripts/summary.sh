#!/bin/sh -eu
# Summarize the current user's assigned todo tickets (read-only).
#
# Reuses drive/list-todo.sh for the current-user scoping (todo/<user-slug>/,
# derived from git config user.email via gather/user-slug.sh) so "assigned to me"
# stays defined in exactly one place, then enriches each ticket with its H1 title
# and frontmatter type/layer/depends_on. Creates nothing; reads only.
#
# Usage: summary.sh
# Output: JSON array [{path, title, type, layer, depends_on}], sorted by path;
#         [] when the current user's queue is empty.

set -eu

SCRIPT_DIR=$(dirname "$0")
PATHS=$(sh "${SCRIPT_DIR}/../../drive/scripts/list-todo.sh")

# JSON-escape a value (backslash and double-quote only; ticket text is plain).
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Read a frontmatter field's value ("" when absent).
fm_field() {
    grep -m1 "^$2:" "$1" 2>/dev/null | sed -e "s/^$2:[ \t]*//" || true
}

# The ticket's H1 title ("" when absent).
h1_title() {
    grep -m1 '^# ' "$1" 2>/dev/null | sed -e 's/^# //' || true
}

OUT="["
FIRST=1
for f in $PATHS; do
    [ -f "$f" ] || continue
    title=$(json_escape "$(h1_title "$f")")
    type=$(json_escape "$(fm_field "$f" type)")
    layer=$(json_escape "$(fm_field "$f" layer)")
    depends_on=$(json_escape "$(fm_field "$f" depends_on)")
    path=$(json_escape "$f")
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"path\":\"${path}\",\"title\":\"${title}\",\"type\":\"${type}\",\"layer\":\"${layer}\",\"depends_on\":\"${depends_on}\"}"
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
