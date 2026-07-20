#!/bin/sh -eu
# Read a mission's `strategy:` relation and print its strategy slug(s), one per line.
#
# This is the single reader of the mission->strategy relation, the mirror of
# mission/scripts/read-relation.sh (which reads an artifact's `mission:` relation).
# Every place that needs "which strategy does this mission execute" calls this instead
# of parsing frontmatter itself, so the field's shape lives in exactly one place.
#
# Usage: read-strategy-relation.sh <mission-file>
# Output: zero or more slugs, one per line. Nothing at all when the field is absent,
#         empty, or the file has no frontmatter. Never fails on a malformed file.
#
# Convention is ONE strategy per mission (a mission is the execution plan of a single
# strategy). The reader still tolerates the inline-list form so a future many-valued
# turn needs no migration:
#
#   strategy: alpha          -> alpha            (the correct spelling for the one case)
#   strategy: [alpha]        -> alpha
#   strategy:                -> (nothing)
#   strategy: []             -> (nothing)

set -eu

FILE="${1:-}"
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

# Pull the raw `strategy:` value out of the frontmatter block only. First match wins:
# a duplicated key is malformed YAML, and a body line starting with `strategy:` must
# not be read as the relation.
raw=$(awk '
NR == 1 { if ($0 != "---") exit; next }
/^---[ \t]*$/ { exit }
/^strategy:[ \t]*/ { sub(/^strategy:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
' "$FILE" 2>/dev/null || true)

[ -n "$raw" ] || exit 0

# Split an inline list into lines; a bare scalar falls through unchanged. Same wire
# shape as mission/scripts/read-relation.sh.
printf '%s\n' "$raw" \
  | tr -d '[]' \
  | tr ',' '\n' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' || true
