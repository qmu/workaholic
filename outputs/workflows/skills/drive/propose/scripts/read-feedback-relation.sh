#!/bin/sh -eu
# Read a mission's `feedback:` relation and print the referenced feedback record
# filename(s), one per line - the single reader of the mission->feedback
# relation (the mirror of mission/scripts/read-relation.sh). Tolerates the
# inline-list and bare-scalar forms, reads the frontmatter block only, and never
# fails on a malformed/missing file.
#
#   feedback: [a.md, b.md]  -> a.md / b.md
#   feedback: a.md          -> a.md
#   feedback:               -> (nothing)
#
# Usage: read-feedback-relation.sh <mission-file>

set -eu

FILE="${1:-}"
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

raw=$(awk '
NR == 1 { if ($0 != "---") exit; next }
/^---[ \t]*$/ { exit }
/^feedback:[ \t]*/ { sub(/^feedback:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
' "$FILE" 2>/dev/null || true)

[ -n "$raw" ] || exit 0

printf '%s\n' "$raw" \
  | tr -d '[]' \
  | tr ',' '\n' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' || true
