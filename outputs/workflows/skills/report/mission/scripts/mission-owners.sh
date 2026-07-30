#!/bin/sh -eu
# Resolve who owns a mission — the ownership oracle every consumer reads through.
#
# Ownership is CARRIED ON THE MISSION (2026-07-28 — the loop-engineering
# reorganization; see mission/reference/schema.md's Ownership section and
# docs/loop-engineering-workflow.md decisions B3/B4). A mission's own plural
# `assignees:` is the primary source; the approver/creator is the default owner,
# and an empty list means the mission is team-owned — unclaimed work, surfaced to
# everyone as claimable.
#
# Resolution order (first non-empty wins):
#
#   1. the mission's own `assignees:` (plural — a mission can be co-owned), read
#      through read-assignees.sh, the single parser of the `assignees` field
#      shape (list + bare forms);
#   2. LEGACY FALLBACK: the mission's own singular `assignee:`, so missions
#      predating the plural field are never orphaned.
#
# The strategy hop (2026-07-24 — owners derived from the linked strategy's
# `assignees`) is GONE with the strategy layer's retirement; the living migration
# (migrate-strategies.sh) folds strategy assignees down into each linked active
# mission's own `assignees` on the next mission-script touch, so nothing is
# orphaned by the removal.
#
# Usage: mission-owners.sh <mission-file>
# Output: zero or more owners, one per line. Never fails on a malformed/missing file.

set -eu

FILE="${1:-}"
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

SCRIPT_DIR=$(dirname "$0")

# 1. The mission's own plural `assignees:` — the primary source. read-assignees.sh
# parses the field shape (frontmatter-only, list + bare forms), so the shape lives
# in exactly one place.
own=$(sh "${SCRIPT_DIR}/read-assignees.sh" "$FILE" 2>/dev/null || true)
if [ -n "$own" ]; then
    printf '%s\n' "$own"
    exit 0
fi

# 2. Legacy fallback: the mission's own singular `assignee:` (frontmatter only).
awk '
NR == 1 { if ($0 != "---") exit; next }
/^---[ \t]*$/ { exit }
/^assignee:[ \t]*/ { sub(/^assignee:[ \t]*/, ""); sub(/[ \t]+$/, ""); if (length($0) > 0) print; exit }
' "$FILE" 2>/dev/null || true
