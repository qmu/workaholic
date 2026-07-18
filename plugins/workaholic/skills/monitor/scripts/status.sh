#!/bin/sh -eu
# monitor/status.sh — objective per-mission run status for the /monitor loop
# (read-only; creates and mutates nothing).
#
# After each drive wave, /monitor decides per mission: complete, still
# driveable, or escalation-blocked. The first two are objective facts and live
# here; the third is semantic (which blockers the developer left unanswered)
# and stays the command's judgment. This script emits only what can be derived:
#
#   - complete: the mission's ## Acceptance is non-empty and fully checked
#     (progress.sh's derived checked/total — 0/0 is NOT complete; a mission
#     with no plan has nothing to have finished).
#   - todo_count: how many tickets remain in the worktree's own todo queue for
#     the current user (drive/list-todo.sh run inside the worktree, so "whose
#     queue" stays defined in one place).
#   - gate_type: the mission's optional gate declaration, so the caller knows
#     whether completion additionally requires exercising a gate (gate.sh is
#     the reader for the rest of the declaration).
#
# Usage: status.sh <worktree_path> [slug]
#   slug defaults to the worktree basename (slug.sh keys .worktrees/<slug> 1:1
#   to the mission slug, so the basename IS the slug on the sanctioned layout).
# Output (JSON):
#   {"slug", "checked", "total", "complete", "todo_count", "gate_type"}
#   or {"slug", "error": "no_mission"} when the worktree holds no mission.md.

set -eu

WT="${1:-}"
if [ -z "$WT" ] || [ ! -d "$WT" ]; then
    echo '{"error": "no_worktree"}'
    exit 0
fi
SLUG="${2:-$(basename "$WT")}"

# Absolute, because the todo count below cd's into the worktree — a relative
# SCRIPT_DIR would stop resolving there.
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts"
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts"

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# active/ area first, then the legacy flat layout (same fallback as preflight.sh).
if [ -f "$WT/.workaholic/missions/active/$SLUG/mission.md" ]; then
    FILE="$WT/.workaholic/missions/active/$SLUG/mission.md"
elif [ -f "$WT/.workaholic/missions/$SLUG/mission.md" ]; then
    FILE="$WT/.workaholic/missions/$SLUG/mission.md"
else
    printf '{"slug": "%s", "error": "no_mission"}\n' "$(json_escape "$SLUG")"
    exit 0
fi

PROG=$(sh "${MISSION_SCRIPTS}/progress.sh" "$FILE" 2>/dev/null || printf '{"checked": 0, "total": 0}')
CHECKED=$(printf '%s' "$PROG" | sed -e 's/.*"checked": *//' -e 's/[,}].*//')
TOTAL=$(printf '%s' "$PROG" | sed -e 's/.*"total": *//' -e 's/[,}].*//')

COMPLETE=false
if [ "${TOTAL:-0}" -gt 0 ] && [ "${CHECKED:-0}" -eq "${TOTAL}" ]; then
    COMPLETE=true
fi

# list-todo.sh lists the current user's todo/<user>/ queue relative to its cwd;
# run it inside the worktree so the count is that mission's own queue. grep -c
# prints 0 (exit 1) on an empty listing, so the `|| true` keeps set -e quiet.
TODO_COUNT=$( (cd "$WT" && sh "${DRIVE_SCRIPTS}/list-todo.sh" 2>/dev/null || true) | grep -c . || true)
TODO_COUNT=${TODO_COUNT:-0}

GATE_TYPE=$(grep -m1 '^gate_type:' "$FILE" 2>/dev/null | sed -e 's/^gate_type:[ \t]*//' -e 's/[ \t]*$//' || true)

printf '{"slug":"%s","checked":%d,"total":%d,"complete":%s,"todo_count":%d,"gate_type":"%s"}\n' \
    "$(json_escape "$SLUG")" "$CHECKED" "$TOTAL" "$COMPLETE" "$TODO_COUNT" "$(json_escape "$GATE_TYPE")"
