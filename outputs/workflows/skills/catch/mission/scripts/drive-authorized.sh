#!/bin/sh -eu
# Answer, for ONE ticket: is this ticket's queue pre-authorized to drive without the
# per-ticket approval prompt?
#
# WHY THIS IS A SCRIPT AND NOT PROSE. The /drive approval gate lived entirely in
# drive/SKILL.md as prose, which is why neither it nor night mode ever had a single
# assertion: there was nothing to call. A rule that decides whether to ask a human for
# permission is exactly the rule that must be reproducible and testable, so it is a
# script. /drive consults this instead of deciding in prose, and night mode gets coverage
# as a side effect.
#
# THE RULE. Explicit approval is RELOCATED, never removed -- and since 2026-07-31 it
# lives in the PULL REQUEST (docs/loop-engineering-workflow.md K1). A mission reaches
# missions/active/ on `main` only by merging the PR it was published behind, and that
# merge IS the project accepting it. So this script no longer reads a status word to
# find authorization: a ticket is gate-free when every mission it names is IN FLIGHT
# (not ended) and carries a plan. `status: approved` and `status: draft` are both
# retired; a checkout still carrying either reads as an ordinary in-flight mission,
# so nothing silently loses its authorization mid-drive while the living migration
# has not yet touched it.
#
# The long-retired `drive_authorized: true` stamp (folded into `status: approved` by
# I2, 2026-07-28) is no longer consulted at all -- it selected between two in-flight
# states that no longer exist, so honoring it could only produce a distinction the
# rest of the system cannot express.
#
# CONSERVATIVE BY CONSTRUCTION. A ticket relating to several missions is authorized only
# if EVERY mission it claims says so. Naming a mission is a commitment, not a label --
# the same reason /drive holds a ticket to the gate of every mission it names, "all of
# them must pass, not the most convenient one". One unauthorized mission means ask.
#
# THE FLOOR. A merged mission is not automatically a plan: a hand-edited mission with
# an empty ## Acceptance (0/0) would authorize unattended work with no bar at all --
# the exact state the interrogation exists to prevent. So authorization additionally
# requires every claimed mission to carry at least one acceptance item
# (progress.sh's total > 0). The floor lands HERE, at the authorization
# decision, where a test can reach it.
#
# Usage: drive-authorized.sh <ticket-file>
# Output: {"authorized": <bool>, "reason": "<why>", "missions": ["<slug>", ...]}
#   reason: ""                  authorized
#           "no_ticket"         the ticket file does not exist
#           "no_mission"        the ticket claims no mission -- nothing authorized it
#           "mission_not_found" a claimed mission does not resolve
#           "not_active"        a claimed mission has ENDED (achieved | abandoned |
#                               carried) -- history authorizes nothing. This replaces
#                               the retired `not_authorized`, which meant "not
#                               `status: approved`" and could no longer be true of an
#                               in-flight mission once `draft` was retired (K1)
#           "no_plan"           a claimed mission is in flight but has an empty ## Acceptance

set -eu

TICKET="${1:-}"
[ -n "$TICKET" ] || { echo '{"authorized": false, "reason": "no_ticket", "missions": []}'; exit 0; }
[ -f "$TICKET" ] || { echo '{"authorized": false, "reason": "no_ticket", "missions": []}'; exit 0; }

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
# Resolution follows the TICKET, not the process cwd: the mission tree is the one the
# ticket lives in (its own worktree), so a bare slug resolves against that tree from any
# cwd. Deriving the root from anything ambient would let a same-slug mission in a sibling
# tree silently lend or withhold its authorization depending on where this ran.
MISSION_ROOT=$(missions_root_from_artifact "$TICKET")
missions_migrate_layout "$MISSION_ROOT"

# The relation is many-valued and is read through the single reader, never re-parsed
# here -- `mission: [a, b]` and a bare `mission: a` must behave identically, and that
# shape is defined in exactly one place.
SLUGS=$(sh "${SCRIPT_DIR}/read-relation.sh" "$TICKET" 2>/dev/null || true)

if [ -z "$SLUGS" ]; then
    echo '{"authorized": false, "reason": "no_mission", "missions": []}'
    exit 0
fi

json_list=""
reason=""
for slug in $SLUGS; do
    [ -z "$json_list" ] && json_list="\"${slug}\"" || json_list="${json_list}, \"${slug}\""
    [ -n "$reason" ] && continue   # already refused; keep collecting slugs for the report

    f=$(mission_resolve "$MISSION_ROOT" "$slug")
    if [ ! -f "$f" ]; then
        reason="mission_not_found"
        continue
    fi
    # BEING IN FLIGHT IS THE AUTHORIZATION (K1) -- the merge that put this mission on
    # `main` was the approval. Only an ENDED mission refuses; every in-flight spelling
    # (`active`, and the retired `draft`/`approved` in a checkout the living migration
    # has not rewritten) passes, so nothing loses authorization mid-drive.
    status=$(grep -m1 '^status:' "$f" 2>/dev/null | sed -e 's/^status:[ \t]*//' -e 's/[ \t]*$//' || true)
    case "$status" in
        achieved | abandoned | carried)
            reason="not_active"
            continue
            ;;
    esac
    # The floor: an in-flight mission must have a plan. total comes from the one
    # progress reader (derived, never stored).
    total=$(sh "${SCRIPT_DIR}/progress.sh" "$f" 2>/dev/null | sed -n 's/.*"total": *\([0-9][0-9]*\).*/\1/p' || true)
    [ "${total:-0}" -gt 0 ] || reason="no_plan"
done

if [ -n "$reason" ]; then
    printf '{"authorized": false, "reason": "%s", "missions": [%s]}\n' "$reason" "$json_list"
else
    printf '{"authorized": true, "reason": "", "missions": [%s]}\n' "$json_list"
fi
