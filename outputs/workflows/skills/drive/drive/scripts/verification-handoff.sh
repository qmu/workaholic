#!/bin/sh -eu
# Derive whether a PR-unit was DECLARED unverifiable in an unattended environment,
# so the run must hand it to a person instead of merging it.
#
#   verification-handoff.sh mission <slug-or-file>
#   verification-handoff.sh tickets <ticket-file>...
#
# Output: JSON
#   {"handoff": true|false, "kind": "mission"|"tickets", "unit": "<id>",
#    "members": [{"id": "...", "verification_handoff": "..."}],
#    "reason": "<the declared reason, verbatim>", "member": "<id>", "missing": [...]}
#
# THE SIGNAL IS A FIELD, DECLARED IN ADVANCE, AND ITS VALUE IS THE REASON.
# `verification_handoff:` is optional ticket/mission frontmatter. Non-empty means
# "the real-world verification this work needs cannot be run where an unattended
# run executes -- the credentials, the device, or the environment are not there",
# and the value NAMES what cannot run. Absent or empty means the ordinary route.
# It is free text on purpose: the value is quoted verbatim into the pull request's
# `## Handoff` section, and an enum could not say which verification is missing.
#
# WHY A FIELD AND NOT AN INFERENCE FROM THE QUALITY GATE. A routing decision made
# by reading prose is a guess, and this one decides whether machinery merges to
# `main`. It is also why the declaration must exist BEFORE the drive: a run that
# could declare its own unit unverifiable mid-drive would have exactly the soft
# landing `handoff` is written never to become (`../SKILL.md` §7).
#
# ANY MEMBER DECLARING IT WINS, for the same reason `review` wins in
# effective-policy.sh: the unit is one merge. Half a pull request cannot be handed
# to a person while the other half merges.
#
# THIS SCRIPT ANSWERS "CAN ITS VERIFICATION RUN HERE", NEVER "MAY IT MERGE".
# effective-policy.sh answers the merge-policy axis and this one answers the
# verification axis; they are read together at route time and deliberately not
# folded into one script, because a unit can be `auto` and still unverifiable here
# -- and `auto` has never meant "no gate applies".
#
# A MEMBER FILE THAT DOES NOT EXIST IS REPORTED, NEVER TREATED AS A DECLARATION.
# An absent file cannot declare anything, and defaulting it to `handoff` would let
# a typo'd path stop a merge; effective-policy.sh already refuses to merge a unit
# with a `not_found` member, so the safe side is covered there rather than twice.
#
# Pure read: it inspects frontmatter and writes nothing.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

KIND="${1:-}"
case "$KIND" in
    mission | tickets) shift ;;
    *)
        echo 'Usage: verification-handoff.sh mission <slug-or-file> | verification-handoff.sh tickets <ticket-file>...' >&2
        exit 1
        ;;
esac

if [ "$#" -eq 0 ]; then
    echo 'Usage: verification-handoff.sh mission <slug-or-file> | verification-handoff.sh tickets <ticket-file>...' >&2
    exit 1
fi

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Read one frontmatter key from a file ("" when absent) -- the plugin's standard
# shape: first match inside the leading --- block wins.
fm_field() {
    awk -v key="$2" '
        NR == 1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        index($0, key ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$1" 2>/dev/null || true
}

MEMBERS=""
sep=""
MISSING=""
msep=""
HANDOFF="false"
REASON=""
DECLARER=""

# Record one member's declaration. The FIRST declaration is the reported reason,
# but every member is still listed: a unit handed off for two different missing
# verifications owes the reader both, and the report that stopped at the first
# would hide the second.
consider() {
    _c_id="$1"
    _c_value="$2"
    MEMBERS="${MEMBERS}${sep}{\"id\": \"$(json_escape "$_c_id")\", \"verification_handoff\": \"$(json_escape "$_c_value")\"}"
    sep=", "
    if [ -n "$_c_value" ] && [ -z "$REASON" ]; then
        HANDOFF="true"
        REASON="$_c_value"
        DECLARER="$_c_id"
    fi
}

classify() {
    _f="$1"
    _id="$2"
    if [ ! -f "$_f" ]; then
        MISSING="${MISSING}${msep}\"$(json_escape "$_id")\""
        msep=", "
        consider "$_id" ""
        return 0
    fi
    consider "$_id" "$(fm_field "$_f" verification_handoff)"
}

case "$KIND" in
    mission)
        UNIT="$1"
        . "${SCRIPT_DIR}/../../mission/scripts//lib/resolve.sh"
        ROOT=$(missions_root_for_arg "$UNIT")
        FILE=$(mission_resolve "$ROOT" "$UNIT")
        case "$FILE" in
            */mission.md) UNIT=$(basename "$(dirname "$FILE")") ;;
        esac
        classify "$FILE" "$UNIT"
        ;;
    tickets)
        # A batch's unit id is minted by claim.sh, not here -- like effective-policy.sh,
        # this may run before the claim as well as after.
        UNIT="batch"
        for t in "$@"; do
            classify "$t" "$t"
        done
        ;;
esac

printf '{"handoff": %s, "kind": "%s", "unit": "%s", "members": [%s], "reason": "%s", "member": "%s", "missing": [%s]}\n' \
    "$HANDOFF" "$KIND" "$(json_escape "$UNIT")" "$MEMBERS" "$(json_escape "$REASON")" "$(json_escape "$DECLARER")" "$MISSING"
