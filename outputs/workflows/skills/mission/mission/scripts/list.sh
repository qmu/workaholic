#!/bin/sh -eu
# List every mission with its status and computed progress (checked/total).
# Missions are enumerated across both areas (active/ and archive/), plus any
# legacy flat dir the migration could not move. Progress is derived per mission
# via progress.sh, never read from a stored number.
#
# Usage: list.sh
# Output: JSON array [{slug, title, status, assignee, relation, next, checked, total,
#         predicted_hours, actual_hours, path}], sorted by slug. Emits [] when there
#         are no missions. predicted_hours/actual_hours are the raw frontmatter values
#         ("" when unset) — the trend surface predict-duration.sh and /catch read.
#
# relation is the caller-centric partition the bare /mission view renders on:
#   mine       — assignee equals the current git user.email (and the email is set)
#   unassigned — assignee is empty (unclaimed; closer to the caller's business
#                than a colleague's mission, so it shares the full treatment)
#   others     — assigned to somebody else
# It applies the same "not somebody else's" gate summary.sh and mission-lens.sh
# inline, computed here so consumers partition without re-deriving it. Unlike
# summary.sh this script never exits on a missing git email — the bare list
# still shows everyone: an empty email just means nothing is "mine".
# next is the first unchecked ## Acceptance item (next-acceptance.sh; "" when
# none) so the full-treatment tier can state each mission's next step.
# Both keys are additive — existing consumers (catch/scan-window.sh, the
# command's replan judge) parse a subset and are unaffected.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT=".workaholic/missions"

if [ ! -d "$ROOT" ]; then
    echo '[]'
    exit 0
fi

. "${SCRIPT_DIR}/lib/resolve.sh"
# list.sh enumerates "the missions in this repo" and reports each mission.md's location
# relative to the cwd (below), so it migrates the same cwd-relative tree it lists.
missions_migrate_layout ".workaholic"

# JSON-escape a value (backslash and double-quote only; titles are plain text).
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Read a frontmatter field's value ("" when absent).
fm_field() {
    grep -m1 "^$2:" "$1" 2>/dev/null | sed -e "s/^$2:[ \t]*//" || true
}

# Mission dirs across both areas plus legacy flat leftovers, sorted globally by
# slug (the dir basename) so the two areas interleave into one slug-ordered list.
DIRS=$(
    {
        find "$ROOT/active" "$ROOT/archive" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
        find "$ROOT" -maxdepth 1 -mindepth 1 -type d ! -name active ! -name archive 2>/dev/null
    } | awk -F/ '{print $NF "\t" $0}' | LC_ALL=C sort | cut -f2-
)

# Current developer identity for the relation partition. Empty (unset email)
# degrades gracefully: nothing matches "mine", the rest still classifies.
EMAIL=$(git config user.email 2>/dev/null || true)

OUT="["
FIRST=1
for d in $DIRS; do
    f="$d/mission.md"
    [ -f "$f" ] || continue
    slug=$(basename "$d")
    title=$(json_escape "$(fm_field "$f" title)")
    status=$(json_escape "$(fm_field "$f" status)")
    raw_assignee=$(fm_field "$f" assignee)
    assignee=$(json_escape "$raw_assignee")
    if [ -z "$raw_assignee" ]; then
        relation="unassigned"
    elif [ -n "$EMAIL" ] && [ "$raw_assignee" = "$EMAIL" ]; then
        relation="mine"
    else
        relation="others"
    fi
    next=$(json_escape "$(sh "${SCRIPT_DIR}/next-acceptance.sh" "$f" 2>/dev/null || true)")
    predicted=$(json_escape "$(fm_field "$f" predicted_hours)")
    actual=$(json_escape "$(fm_field "$f" actual_hours)")
    prog=$(sh "${SCRIPT_DIR}/progress.sh" "$f")
    checked=$(printf '%s' "$prog" | sed -e 's/.*"checked": *//' -e 's/[,}].*//')
    total=$(printf '%s' "$prog" | sed -e 's/.*"total": *//' -e 's/[,}].*//')
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"slug\":\"${slug}\",\"title\":\"${title}\",\"status\":\"${status}\",\"assignee\":\"${assignee}\",\"relation\":\"${relation}\",\"next\":\"${next}\",\"checked\":${checked},\"total\":${total},\"predicted_hours\":\"${predicted}\",\"actual_hours\":\"${actual}\",\"path\":\"${f}\"}"
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
