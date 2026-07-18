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
# THE RULE. Explicit approval is RELOCATED, never removed. A ticket is gate-free only
# when a prior explicit authorization covers it: the developer interrogated the mission
# (see the mission skill's Creation Interrogation), co-authored every ticket's quality
# gate, and the mission was stamped `drive_authorized: true`. Anything else asks.
#
# CONSERVATIVE BY CONSTRUCTION. A ticket relating to several missions is authorized only
# if EVERY mission it claims says so. Naming a mission is a commitment, not a label --
# the same reason /drive holds a ticket to the gate of every mission it names, "all of
# them must pass, not the most convenient one". One unauthorized mission means ask.
#
# THE FLOOR. A stamp alone is not a plan: a hand-stamped mission with an empty
# ## Acceptance (0/0) would authorize unattended work with no bar at all — the
# exact state the interrogation exists to prevent. So authorization additionally
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
#           "not_authorized"    a claimed mission is not stamped drive_authorized: true
#           "no_plan"           a claimed mission is stamped but has an empty ## Acceptance

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
    stamp=$(grep -m1 '^drive_authorized:' "$f" 2>/dev/null | sed -e 's/^drive_authorized:[ \t]*//' -e 's/[ \t]*$//' || true)
    if [ "$stamp" != "true" ]; then
        reason="not_authorized"
        continue
    fi
    # The floor: a stamped mission must have a plan. total comes from the one
    # progress reader (derived, never stored).
    total=$(sh "${SCRIPT_DIR}/progress.sh" "$f" 2>/dev/null | sed -n 's/.*"total": *\([0-9][0-9]*\).*/\1/p' || true)
    [ "${total:-0}" -gt 0 ] || reason="no_plan"
done

if [ -n "$reason" ]; then
    printf '{"authorized": false, "reason": "%s", "missions": [%s]}\n' "$reason" "$json_list"
else
    printf '{"authorized": true, "reason": "", "missions": [%s]}\n' "$json_list"
fi
