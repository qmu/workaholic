#!/bin/sh -eu
# Resolve who owns a mission — the ownership oracle every consumer reads through.
#
# Ownership is CARRIED ON THE MISSION (2026-07-28 — the loop-engineering
# reorganization returned it from the strategy layer, whose retirement is staged
# work; see mission/SKILL.md's Ownership section and docs/loop-engineering-workflow.md
# decision B4). A mission's own plural `assignees:` is the primary source; the
# approver/creator is the default owner, and an empty list means the mission is
# team-owned — unclaimed work, surfaced to everyone as claimable.
#
# Resolution order (first non-empty wins):
#
#   1. the mission's own `assignees:` (plural — a mission can be co-owned), read
#      through strategy/scripts/read-assignees.sh, the single parser of the
#      `assignees` field shape (list + bare forms);
#   2. TRANSITION FALLBACK: the strategy hop — mission `strategy:` link -> that
#      strategy's `assignees` — kept so missions created under the 2026-07-24
#      strategy-ownership model keep their owners until the strategy layer's
#      retirement migrates them down;
#   3. LEGACY FALLBACK: the mission's own singular `assignee:`, so missions
#      predating every ownership model are never orphaned.
#
# Usage: mission-owners.sh <mission-file>
# Output: zero or more owners, one per line. Never fails on a malformed/missing file.

set -eu

FILE="${1:-}"
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

SCRIPT_DIR=$(dirname "$0")
STRATEGY_SCRIPTS="${SCRIPT_DIR}/../../strategy/scripts"

# 1. The mission's own plural `assignees:` — the primary source. read-assignees.sh
# parses the field shape generically (frontmatter-only, list + bare forms), so the
# shape lives in exactly one place.
own=$(sh "${STRATEGY_SCRIPTS}/read-assignees.sh" "$FILE" 2>/dev/null || true)
if [ -n "$own" ]; then
    printf '%s\n' "$own"
    exit 0
fi

# 2. Transition fallback: derive from the linked strategy's assignees.
# The .workaholic root of THIS mission's checkout, derived from the mission path so the
# strategy is resolved in the same tree (works for main-tree relative paths and absolute
# worktree paths alike): strip everything from "/missions/" onward.
WROOT="${FILE%%/missions/*}"

sslug=$(sh "${STRATEGY_SCRIPTS}/read-strategy-relation.sh" "$FILE" 2>/dev/null | head -n 1 || true)

if [ -n "$sslug" ]; then
    # Search active/ then archive/ so an archived strategy never dangles ownership.
    sfile=""
    if [ -f "${WROOT}/strategies/active/${sslug}/strategy.md" ]; then
        sfile="${WROOT}/strategies/active/${sslug}/strategy.md"
    elif [ -f "${WROOT}/strategies/archive/${sslug}/strategy.md" ]; then
        sfile="${WROOT}/strategies/archive/${sslug}/strategy.md"
    fi
    if [ -n "$sfile" ]; then
        owners=$(sh "${STRATEGY_SCRIPTS}/read-assignees.sh" "$sfile" 2>/dev/null || true)
        if [ -n "$owners" ]; then
            printf '%s\n' "$owners"
            exit 0
        fi
    fi
fi

# 3. Legacy fallback: the mission's own singular `assignee:` (frontmatter only).
awk '
NR == 1 { if ($0 != "---") exit; next }
/^---[ \t]*$/ { exit }
/^assignee:[ \t]*/ { sub(/^assignee:[ \t]*/, ""); sub(/[ \t]+$/, ""); if (length($0) > 0) print; exit }
' "$FILE" 2>/dev/null || true
