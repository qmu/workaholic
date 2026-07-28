#!/bin/sh -eu
# List every mission with its status and computed progress (checked/total).
# Missions are enumerated across both areas (active/ and archive/), plus any
# legacy flat dir the migration could not move. Progress is derived per mission
# via progress.sh, never read from a stored number.
#
# Usage: list.sh
# Output: JSON array [{slug, title, status, assignee, owners, relation, next,
#         checked, total, drive_authorized, ready, ready_reason, predicted_hours,
#         actual_hours, path}], sorted by slug. Emits [] when there are no missions.
#         predicted_hours/actual_hours are the raw frontmatter values ("" when unset) —
#         the trend surface predict-duration.sh and /catch read.
#
# relation is the caller-centric partition the bare /mission view renders on:
#   mine       — the caller is among the mission's owners (and the email is set)
#   unassigned — the mission has no owners (unclaimed; closer to the caller's
#                business than a colleague's mission, so it shares the full treatment)
#   others     — owned by somebody else (owners present, caller not among them)
# Ownership resolves through mission-owners.sh (the mission's own `assignees`,
# with a legacy fallback to its singular `assignee`) — not read from the mission's
# frontmatter here — so the shape lives in exactly one place. `assignee` is
# the FIRST owner ("" when unowned), aliased for back-compat; `owners` is
# the full set. Unlike summary.sh this script never exits on a missing git
# email — the bare list still shows everyone: an empty email just means nothing is
# "mine".
# next is the first unchecked ## Acceptance item (next-acceptance.sh; "" when
# none) so the full-treatment tier can state each mission's next step.
# drive_authorized is the raw frontmatter value; ready is the /mission planning
# session's drive-readiness verdict (active AND has a plan AND drive_authorized);
# ready_reason names the blocker (no_plan / not_authorized / not_active / draft) so the
# session can explain what a replan must fix. All additive — existing consumers
# (catch/scan-window.sh, the command's replan judge) parse a subset and are
# unaffected.

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
    # Ownership (the mission's own assignees, legacy singular fallback) via the
    # single oracle — never parsed here. owners is the full set; assignee aliases the
    # first for back-compat; relation is the caller-centric partition.
    owners_raw=$(sh "${SCRIPT_DIR}/mission-owners.sh" "$f" 2>/dev/null || true)
    owners_json=""
    first_owner=""
    is_mine=0
    for o in $owners_raw; do
        [ -n "$first_owner" ] || first_owner="$o"
        [ -n "$EMAIL" ] && [ "$o" = "$EMAIL" ] && is_mine=1
        if [ -n "$owners_json" ]; then
            owners_json="${owners_json},\"$(json_escape "$o")\""
        else
            owners_json="\"$(json_escape "$o")\""
        fi
    done
    assignee=$(json_escape "$first_owner")
    if [ -z "$owners_raw" ]; then
        relation="unassigned"
    elif [ "$is_mine" -eq 1 ]; then
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
    # Drive-readiness for the /mission planning session: an active mission is
    # ready when it has a plan (total > 0) AND is stamped drive_authorized: true.
    # ready_reason names the blocker so the session can explain what a replan must
    # fix — no_plan (empty ## Acceptance) or not_authorized (unstamped). Only an
    # active mission can be "ready"; a DRAFT (an unapproved proposal from the
    # /propose batch) reports its own distinct reason so the roadmap can show it
    # as awaiting approval, not as a replan target; archived ones report
    # ready:false, done.
    drive_auth=$(fm_field "$f" drive_authorized)
    ready=false
    ready_reason=""
    if [ "$status" = "draft" ]; then
        ready_reason="draft"
    elif [ "$status" != "active" ]; then
        ready_reason="not_active"
    elif [ "${total:-0}" -eq 0 ]; then
        ready_reason="no_plan"
    elif [ "$drive_auth" != "true" ]; then
        ready_reason="not_authorized"
    else
        ready=true
    fi
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"slug\":\"${slug}\",\"title\":\"${title}\",\"status\":\"${status}\",\"assignee\":\"${assignee}\",\"owners\":[${owners_json}],\"relation\":\"${relation}\",\"next\":\"${next}\",\"checked\":${checked},\"total\":${total},\"drive_authorized\":\"$(json_escape "$drive_auth")\",\"ready\":${ready},\"ready_reason\":\"${ready_reason}\",\"predicted_hours\":\"${predicted}\",\"actual_hours\":\"${actual}\",\"path\":\"${f}\"}"
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
