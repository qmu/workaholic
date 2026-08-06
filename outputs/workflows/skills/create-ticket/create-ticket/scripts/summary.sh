#!/bin/sh -eu
# Summarize the current user's assigned todo tickets (read-only).
#
# Reads the whole queue through drive/list-todo.sh, then keeps what this developer
# owns — plus what nobody owns, since team-owned work is claimable by anyone and a
# view that hid it would hide the queue's most actionable half. "Assigned to me"
# stays defined in exactly one place (gather/scripts/owns.sh, the one ownership
# oracle), which is what makes this view and /drive's survey unable to disagree.
# Each kept ticket is enriched with its H1 title and frontmatter
# type/layer/depends_on. Creates nothing; reads only.
#
# Before P2 (2026-08-06) the scoping was the directory `todo/<user-slug>/` and
# list-todo.sh applied it; the shape of this script is unchanged because the
# ownership question simply moved from the path to a field.
#
# Usage: summary.sh
# Output: JSON array [{path, title, type, layer, depends_on, owners}], sorted by
#         path; [] when nothing in the queue is this developer's or unowned.

set -eu

SCRIPT_DIR=$(dirname "$0")
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"
PATHS=$(sh "${SCRIPT_DIR}/../../drive/scripts//list-todo.sh")
ME=$(git config user.email 2>/dev/null || true)

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
    case "$(sh "${GATHER_SCRIPTS}/owns.sh" "$f" "$ME" 2>/dev/null || echo unowned)" in
        mine|unowned) : ;;
        *) continue ;;
    esac
    owners=$(json_escape "$(sh "${GATHER_SCRIPTS}/owners.sh" "$f" 2>/dev/null | tr '\n' ' ' | sed 's/ *$//' || true)")
    title=$(json_escape "$(h1_title "$f")")
    type=$(json_escape "$(fm_field "$f" type)")
    layer=$(json_escape "$(fm_field "$f" layer)")
    depends_on=$(json_escape "$(fm_field "$f" depends_on)")
    path=$(json_escape "$f")
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"path\":\"${path}\",\"title\":\"${title}\",\"type\":\"${type}\",\"layer\":\"${layer}\",\"depends_on\":\"${depends_on}\",\"owners\":\"${owners}\"}"
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
