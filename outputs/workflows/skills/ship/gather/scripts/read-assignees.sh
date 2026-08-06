#!/bin/sh -eu
# Read a file's `assignees:` frontmatter field and print its owner id(s)/email(s),
# one per line — the single parser of the `assignees` field shape.
#
# Born as the strategy skill's reader (2026-07-24) and relocated into the mission
# skill when ownership returned to the mission and the strategy layer retired
# (2026-07-28 — docs/loop-engineering-workflow.md B3/B4). gather/scripts/owners.sh calls
# this on mission.md as its primary tier; every place that needs "who does this
# file's assignees name" calls this instead of parsing frontmatter itself, so the
# field's shape lives in exactly one place.
#
# `assignees` is a LIST by design — an artifact can be co-owned. The reader
# tolerates both the inline-list and the bare-scalar forms:
#
#   assignees: [a@x, b@y]    -> a@x / b@y   (the common co-owned form)
#   assignees: a@x           -> a@x         (a single owner, bare, also fine)
#   assignees:               -> (nothing)   (unowned — visible to everyone, claimable)
#   assignees: []            -> (nothing)
#
# Usage: read-assignees.sh <file>
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

# Split an inline list into lines; a bare scalar falls through unchanged.
printf '%s\n' "$raw" \
  | tr -d '[]' \
  | tr ',' '\n' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' || true
