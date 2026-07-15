#!/bin/sh -eu
# Read an artifact's `mission:` relation and print one mission slug per line.
#
# This is the single reader of the relation. Every seam that rolls a mission (drive
# archive, ship extract-deferred-concerns, report apply-deferred-concern-verdicts, catch
# scan-window) calls this instead of carrying its own frontmatter parser, so the shape of
# the field is defined in exactly one place and the four copies cannot drift.
#
# Usage: read-relation.sh <artifact-file>
# Output: zero or more slugs, one per line. Nothing at all when the field is absent,
#         empty, or the file has no frontmatter. Never fails on a malformed file.
#
# The relation is MANY-valued. An artifact records every mission it advances:
#
#   mission: [alpha, beta]   -> alpha\nbeta      (the current shape)
#   mission: alpha           -> alpha            (a bare scalar still reads as one slug)
#   mission:                 -> (nothing)
#   mission: []              -> (nothing)
#
# The scalar form is not deprecated-and-tolerated — it is the correct spelling for the
# common case of one mission, and the ~15 artifacts written before the field was widened
# must keep parsing untouched. Emission is forward-only; nothing backfills them.
#
# Why a list at all: an artifact can genuinely advance two missions, and the field used to
# hold one. `report` resolved that by asking the developer to pick a mission and discard
# the rest, which made the mission graph depend on which option someone clicked and
# under-counted the mission that lost. Every other relation in the model was already
# plural (`tickets: []`, `stories: []`, `concerns: []`); this one was the odd one out.
#
# Note this reads a relation ON an artifact. It is NOT for mission.md's own fields
# (title/status/assignee/gate_*) — those are read by list.sh and friends.

set -eu

FILE="${1:-}"
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

# Pull the raw `mission:` value out of the frontmatter block only. First match wins here
# on purpose: a duplicated key is malformed YAML, and a body line that happens to start
# with `mission:` must not be read as the relation.
raw=$(awk '
NR == 1 { if ($0 != "---") exit; next }
/^---[ \t]*$/ { exit }
/^mission:[ \t]*/ { sub(/^mission:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
' "$FILE" 2>/dev/null || true)

[ -n "$raw" ] || exit 0

# Split an inline list into lines; a bare scalar falls through this unchanged. Mirrors the
# `layer: [UX, Domain]` parse in hooks/validate-ticket.sh — same wire shape, same reader.
printf '%s\n' "$raw" \
  | tr -d '[]' \
  | tr ',' '\n' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' || true
