#!/bin/sh -eu
# Summarize trip state for `/trip summary` (read-only): every trip under
# .workaholic/trips/ with its plan phase/step/instruction/blocked (via
# read-plan.sh), plus a snapshot of the current user's todo queue that a /trip
# would execute (via drive/list-todo.sh). Creates no worktree, branch, or
# artifact.
#
# Usage: summary.sh
# Output: JSON {"trips": [ {name, phase, step, iteration, instruction,
#         updated_at, blocked} ], "queue": [ "<todo path>" ]}.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT=".workaholic/trips"

# JSON-escape a value (backslash and double-quote only).
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

TRIPS="["
FIRST=1
if [ -d "$ROOT" ]; then
    DIRS=$(find "$ROOT" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort || true)
    for d in $DIRS; do
        [ -f "$d/plan.md" ] || continue
        name=$(basename "$d")
        # read-plan.sh already emits a well-escaped JSON object; graft the trip
        # name onto it by replacing the leading brace, preserving its escaping.
        plan=$(sh "${SCRIPT_DIR}/read-plan.sh" "$d")
        rest=${plan#\{}
        [ "$FIRST" -eq 1 ] || TRIPS="${TRIPS},"
        FIRST=0
        TRIPS="${TRIPS}{\"name\":\"$(json_escape "$name")\",${rest}"
    done
fi
TRIPS="${TRIPS}]"

QUEUE="["
FIRST=1
PATHS=$(sh "${SCRIPT_DIR}/../../drive/scripts/list-todo.sh" || true)
for p in $PATHS; do
    [ "$FIRST" -eq 1 ] || QUEUE="${QUEUE},"
    FIRST=0
    QUEUE="${QUEUE}\"$(json_escape "$p")\""
done
QUEUE="${QUEUE}]"

printf '{"trips": %s, "queue": %s}\n' "$TRIPS" "$QUEUE"
