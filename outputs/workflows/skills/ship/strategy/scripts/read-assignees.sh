#!/bin/sh -eu
# Read a strategy's `assignees:` field and print its owner id(s)/email(s), one per line.
#
# This is the single reader of a strategy's ownership, the mirror of
# read-strategy-relation.sh (which reads a mission's `strategy:` relation). Ownership
# lives on the STRATEGY, not the mission: a strategy is the direction a set of people
# own, and a mission derives its owner from the strategy it executes (see
# mission/scripts/mission-owners.sh). Every place that needs "who owns this strategy"
# calls this instead of parsing frontmatter itself, so the field's shape lives in
# exactly one place.
#
# A strategy MAY be co-owned (several people own one direction), so `assignees` is a
# LIST by design — the plural spelling is deliberate (see strategy/SKILL.md's
# Terminology record). The reader tolerates both the inline-list and the bare-scalar
# forms, identical to read-strategy-relation.sh:
#
#   assignees: [a@x, b@y]    -> a@x / b@y   (the common co-owned form)
#   assignees: a@x           -> a@x         (a single owner, bare, also fine)
#   assignees:               -> (nothing)   (unowned — visible to everyone, claimable)
#   assignees: []            -> (nothing)
#
# Usage: read-assignees.sh <strategy-file>
# Output: zero or more owners, one per line. Nothing at all when the field is absent,
#         empty, or the file has no frontmatter. Never fails on a malformed file.

set -eu

FILE="${1:-}"
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

# Pull the raw `assignees:` value out of the frontmatter block only. First match wins:
# a duplicated key is malformed YAML, and a body line starting `assignees:` must not be
# read as the field.
raw=$(awk '
NR == 1 { if ($0 != "---") exit; next }
/^---[ \t]*$/ { exit }
/^assignees:[ \t]*/ { sub(/^assignees:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
' "$FILE" 2>/dev/null || true)

[ -n "$raw" ] || exit 0

# Split an inline list into lines; a bare scalar falls through unchanged. Same wire
# shape as read-strategy-relation.sh.
printf '%s\n' "$raw" \
  | tr -d '[]' \
  | tr ',' '\n' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' || true
