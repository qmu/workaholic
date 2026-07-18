#!/bin/sh -eu
# monitor/preflight.sh — assemble the /monitor pre-flight over the current
# developer's missions (read-only; creates and mutates nothing).
#
# /monitor drives missions in parallel, one autonomous drive per mission
# worktree. Before anything is driven, the developer confirms a pre-flight
# review; this script assembles its facts. It answers, for every mission that
# is the current developer's business (the summary.sh gate: mine, or
# unassigned/claimable — never somebody else's):
#
#   - where the mission lives (its .worktrees/<slug> worktree, or none yet),
#   - how far it stands (derived checked/total + next unchecked acceptance item),
#   - whether it may be driven unattended (the drive-authorized floor).
#
# MISSIONS ARE DISCOVERED IN TWO PLACES, deliberately. A mission created by
# /mission lives inside its own worktree's checkout until its branch merges, so
# the main tree's .workaholic/missions/ does not see it. The pre-flight
# therefore reads (a) every mission-type worktree's own mission.md, then (b)
# main-tree active missions that own no worktree (these need
# create-mission-worktree.sh before they can be driven). A mission-type
# worktree holding no mission.md is reported as an orphan, never guessed at.
#
# THE AUTHORIZATION RULE MIRRORS drive-authorized.sh's per-mission floor
# (stamped drive_authorized: true AND a non-empty ## Acceptance). This is the
# mission-side reading of the same rule — advisory, for the pre-flight; the
# ticket-scoped resolver remains the authority at drive time, and every leaf
# still consults drive-authorized.sh per ticket before skipping the gate.
#
# Usage: preflight.sh
# Output (JSON):
#   {"email": "<me>",
#    "missions": [{"slug", "title", "assignee", "mine", "checked", "total",
#                  "next", "worktree_path", "authorized", "reason"}],
#    "orphan_worktrees": [{"path", "slug"}]}
#   missions: the developer's own first, then unassigned; reason is "" when
#   authorized, else not_authorized | no_plan | no_worktree.

set -eu

SCRIPT_DIR=$(dirname "$0")
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts"
BRANCH_SCRIPTS="${SCRIPT_DIR}/../../branching/scripts"

EMAIL=$(git config user.email 2>/dev/null || true)
if [ -z "$EMAIL" ]; then
    echo '{"email": "", "missions": [], "orphan_worktrees": []}'
    exit 0
fi

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

fm_field() {
    grep -m1 "^$2:" "$1" 2>/dev/null | sed -e "s/^$2:[ \t]*//" -e "s/[ \t]*\$//" || true
}

# Locate a worktree's mission.md for its slug: active/ area first, then the
# legacy flat layout (the living migration runs per-checkout, so a worktree
# may still hold the flat shape). Prints nothing when neither exists.
wt_mission_file() {
    if [ -f "$1/.workaholic/missions/active/$2/mission.md" ]; then
        printf '%s' "$1/.workaholic/missions/active/$2/mission.md"
    elif [ -f "$1/.workaholic/missions/$2/mission.md" ]; then
        printf '%s' "$1/.workaholic/missions/$2/mission.md"
    fi
}

WT_LINES=$(sh "${BRANCH_SCRIPTS}/list-all-worktrees.sh" \
    | jq -r '.worktrees[] | select(.type=="mission") | .worktree_path')

MISSIONS=""
ORPHANS=""
FIRST_M=1
FIRST_O=1
WT_SLUGS=" "

# First sweep: split mission-type worktrees into mission-bearing (WT_SLUGS)
# and orphans. The here-doc keeps the loop in the current shell so the
# accumulators persist (POSIX has no `< <(...)`).
while IFS= read -r wt; do
    [ -n "$wt" ] || continue
    slug=$(basename "$wt")
    f=$(wt_mission_file "$wt" "$slug")
    if [ -z "$f" ]; then
        [ "$FIRST_O" -eq 1 ] || ORPHANS="${ORPHANS},"
        FIRST_O=0
        ORPHANS="${ORPHANS}{\"path\":\"$(json_escape "$wt")\",\"slug\":\"$(json_escape "$slug")\"}"
    else
        WT_SLUGS="${WT_SLUGS}${slug} "
    fi
done <<EOF
$WT_LINES
EOF

# Gate one candidate mission file and append its entry. Skips silently unless
# the mission is active AND passes the current ownership pass. Always returns 0
# so a skip never trips set -e in the caller.
consider() {
    cf="$1"; cwt="$2"; cslug="$3"
    [ "$(fm_field "$cf" status)" = "active" ] || return 0
    cassignee=$(fm_field "$cf" assignee)
    case "$PASS" in
        mine)       [ "$cassignee" = "$EMAIL" ] || return 0 ;;
        unassigned) [ -z "$cassignee" ] || return 0 ;;
    esac
    cprog=$(sh "${MISSION_SCRIPTS}/progress.sh" "$cf" 2>/dev/null || printf '{"checked": 0, "total": 0}')
    cchecked=$(printf '%s' "$cprog" | sed -e 's/.*"checked": *//' -e 's/[,}].*//')
    ctotal=$(printf '%s' "$cprog" | sed -e 's/.*"total": *//' -e 's/[,}].*//')
    cnext=$(json_escape "$(sh "${MISSION_SCRIPTS}/next-acceptance.sh" "$cf" 2>/dev/null || true)")
    cstamp=$(fm_field "$cf" drive_authorized)
    creason=""
    if [ "$cstamp" != "true" ]; then
        creason="not_authorized"
    elif [ "${ctotal:-0}" -eq 0 ]; then
        creason="no_plan"
    elif [ -z "$cwt" ]; then
        creason="no_worktree"
    fi
    if [ -z "$creason" ]; then cauth=true; else cauth=false; fi
    cmine=false
    [ "$PASS" = "mine" ] && cmine=true
    ctitle=$(json_escape "$(fm_field "$cf" title)")
    entry="{\"slug\":\"$(json_escape "$cslug")\",\"title\":\"${ctitle}\",\"assignee\":\"$(json_escape "$cassignee")\",\"mine\":${cmine},\"checked\":${cchecked},\"total\":${ctotal},\"next\":\"${cnext}\",\"worktree_path\":\"$(json_escape "$cwt")\",\"authorized\":${cauth},\"reason\":\"${creason}\"}"
    [ "$FIRST_M" -eq 1 ] || MISSIONS="${MISSIONS},"
    FIRST_M=0
    MISSIONS="${MISSIONS}${entry}"
    return 0
}

# Two ownership passes (summary.sh's ordering: mine first, then unassigned);
# within each, worktree-owned missions come before main-tree ones.
for PASS in mine unassigned; do
    while IFS= read -r wt; do
        [ -n "$wt" ] || continue
        slug=$(basename "$wt")
        f=$(wt_mission_file "$wt" "$slug")
        [ -n "$f" ] || continue
        consider "$f" "$wt" "$slug"
    done <<EOF
$WT_LINES
EOF
    for d in .workaholic/missions/active/*/; do
        [ -d "$d" ] || continue
        d=${d%/}
        slug=$(basename "$d")
        case "$WT_SLUGS" in *" ${slug} "*) continue ;; esac
        f="$d/mission.md"
        [ -f "$f" ] || continue
        consider "$f" "" "$slug"
    done
done

printf '{"email":"%s","missions":[%s],"orphan_worktrees":[%s]}\n' \
    "$(json_escape "$EMAIL")" "$MISSIONS" "$ORPHANS"
