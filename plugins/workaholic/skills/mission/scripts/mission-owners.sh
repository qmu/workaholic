#!/bin/sh -eu
# Resolve who owns a mission — the ownership oracle every consumer reads through.
#
# Ownership lives ON THE STRATEGY, not the mission (2026-07-24 — a deliberate amendment
# of the earlier "a strategy has no assignee" doctrine; see strategy/SKILL.md and
# mission/SKILL.md). A mission's owners are DERIVED, two hops:
#
#   mission.md --strategy:--> strategy slug --assignees:--> owner(s)
#
# read through the single readers only (strategy/scripts/read-strategy-relation.sh for
# the link, strategy/scripts/read-assignees.sh for the owners), never by parsing
# frontmatter here. Prints one owner per line; NOTHING (empty output) means the mission
# is unassigned — unclaimed work, surfaced to everyone as claimable, exactly as an
# empty `assignee` meant before this change.
#
# LEGACY FALLBACK, not a hard cutover. The plugin is installed in other repos whose
# existing missions still carry the old per-mission `assignee:` field and whose
# strategies predate `assignees:`. So when the strategy derivation yields nothing (no
# strategy linked, the strategy is unresolvable, or it has no assignees), fall back to
# the mission's own `assignee:` value. A hard cutover would silently orphan every such
# mission's ownership. Strategy-derived owners WIN when present; the mission field is
# consulted only when they are absent.
#
# Usage: mission-owners.sh <mission-file>
# Output: zero or more owners, one per line. Never fails on a malformed/missing file.

set -eu

FILE="${1:-}"
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

SCRIPT_DIR=$(dirname "$0")
STRATEGY_SCRIPTS="${SCRIPT_DIR}/../../strategy/scripts"

# The .workaholic root of THIS mission's checkout, derived from the mission path so the
# strategy is resolved in the same tree (works for main-tree relative paths and absolute
# worktree paths alike): strip everything from "/missions/" onward.
WROOT="${FILE%%/missions/*}"

# Hop 1: which strategy does this mission execute (first slug; single-valued by convention).
sslug=$(sh "${STRATEGY_SCRIPTS}/read-strategy-relation.sh" "$FILE" 2>/dev/null | head -n 1 || true)

if [ -n "$sslug" ]; then
    # Hop 2: the strategy's assignees. Search active/ then archive/ so an archived
    # strategy never dangles a mission's ownership.
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

# Fallback: the mission's own legacy `assignee:` (frontmatter only; "" prints nothing).
awk '
NR == 1 { if ($0 != "---") exit; next }
/^---[ \t]*$/ { exit }
/^assignee:[ \t]*/ { sub(/^assignee:[ \t]*/, ""); sub(/[ \t]+$/, ""); if (length($0) > 0) print; exit }
' "$FILE" 2>/dev/null || true
