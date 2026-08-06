#!/bin/sh -eu
# List every mission with its status and computed progress (checked/total).
# Missions are enumerated across both areas (active/ and archive/), plus any
# legacy flat dir the migration could not move. Progress is derived per mission
# via progress.sh, never read from a stored number.
#
# Usage: list.sh
# Output: JSON array [{slug, title, status, merge_policy, assignee, owners, relation,
#         next, checked, total, ready, ready_reason, predicted_hours,
#         actual_hours, path}], sorted by slug. Emits [] when there are no missions.
#         predicted_hours/actual_hours are the raw frontmatter values ("" when unset) —
#         the trend surface predict-duration.sh and /catch read.
#
# relation is the caller-centric partition the bare /mission view renders on:
#   mine       — the caller is among the mission's owners (and the email is set)
#   unassigned — the mission has no owners (unclaimed; closer to the caller's
#                business than a colleague's mission, so it shares the full treatment)
#   others     — owned by somebody else (owners present, caller not among them)
# Ownership resolves through gather/scripts/owners.sh (the mission's own `assignees`,
# with a legacy fallback to its singular `assignee`) — not read from the mission's
# frontmatter here — so the shape lives in exactly one place. `assignee` is
# the FIRST owner ("" when unowned), aliased for back-compat; `owners` is
# the full set. Unlike summary.sh this script never exits on a missing git
# email — the bare list still shows everyone: an empty email just means nothing is
# "mine".
# next is the first unchecked ## Acceptance item (next-acceptance.sh; "" when
# none) so the full-treatment tier can state each mission's next step.
# merge_policy is the raw frontmatter value (auto | review | "", where "" reads as
# review), recorded at CREATION since the approval step was retired; ready is the
# /mission planning session's drive-readiness verdict (in flight AND has a plan);
# ready_reason names the blocker (no_plan / not_active / queue_drained) so the session can explain
# what is missing. The retired `draft` and `not_authorized` reasons are gone with
# the draft gate itself (docs/loop-engineering-workflow.md K1), as the
# drive_authorized key went before them (I2).

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
    owners_raw=$(sh "${SCRIPT_DIR}/../../gather/scripts//owners.sh" "$f" 2>/dev/null || true)
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
    # Drive-readiness for the /mission planning session. With `draft` retired
    # (2026-07-31 — docs/loop-engineering-workflow.md K1) there is exactly ONE
    # in-flight state and readiness reduces to "in flight, with a plan": a mission
    # is ready when it has not ended and `total > 0`. ready_reason names the
    # blocker so the session can explain what is missing — `no_plan` (empty
    # ## Acceptance) or `not_active` (an ended mission in the archive area). The
    # retired `draft` reason is gone with the state, as `not_authorized` went
    # before it; legacy `draft`/`approved` files (not yet rewritten by the living
    # migration) read as ordinary in-flight missions.
    merge_policy=$(json_escape "$(fm_field "$f" merge_policy)")
    ready=false
    ready_reason=""
    #
    # `queue_drained` is the fourth reason, and it is the one a DEVELOPER acts on: an
    # active mission whose every ticket was driven and archived is not waiting on a
    # plan, it is waiting on a CLOSE decision. Without it the roadmap showed such a
    # mission as ordinary in-flight work while the survey dropped it as `no_tickets`,
    # so neither view said "this one is done, decide achieved / carried / abandoned".
    # It is deliberately NOT a readiness blocker in the `ready` sense the planning
    # session uses — the mission has a plan; it has finished it.
    case "$status" in
        achieved | abandoned | carried) ready_reason="not_active" ;;
        *)
            if [ "${total:-0}" -eq 0 ]; then
                ready_reason="no_plan"
            else
                ready=true
                qs=$(sh "${SCRIPT_DIR}/queue-size.sh" "$slug" 2>/dev/null || true)
                q_todo=$(printf '%s' "$qs" | sed -n 's/.*"todo": *\([0-9][0-9]*\).*/\1/p')
                q_arch=$(printf '%s' "$qs" | sed -n 's/.*"archive": *\([0-9][0-9]*\).*/\1/p')
                [ -n "$q_todo" ] || q_todo=0
                [ -n "$q_arch" ] || q_arch=0
                if [ "$q_todo" -eq 0 ] && [ "$q_arch" -gt 0 ]; then
                    ready_reason="queue_drained"
                fi
            fi
            ;;
    esac
    [ "$FIRST" -eq 1 ] || OUT="${OUT},"
    FIRST=0
    OUT="${OUT}{\"slug\":\"${slug}\",\"title\":\"${title}\",\"status\":\"${status}\",\"merge_policy\":\"${merge_policy}\",\"assignee\":\"${assignee}\",\"owners\":[${owners_json}],\"relation\":\"${relation}\",\"next\":\"${next}\",\"checked\":${checked},\"total\":${total},\"ready\":${ready},\"ready_reason\":\"${ready_reason}\",\"predicted_hours\":\"${predicted}\",\"actual_hours\":\"${actual}\",\"path\":\"${f}\"}"
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
