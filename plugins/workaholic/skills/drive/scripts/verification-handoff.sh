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

# A HANDOFF THE TICKET DID NOT HAVE TO DECLARE, BECAUSE THE CONTAINER ALREADY KNOWS
# (2026-09-01, issue #793). `verification_handoff:` names what an unattended run cannot VERIFY;
# this names what it cannot DO — the same class one step earlier, and it was fatal in a way the
# declared one is not, because nothing reported it.
#
# MEASURED on a consuming repository, 2026-08-31: every `[Implement]` run from 13:37Z onward read
# `requires_action` — frozen, not idle — each one ending at the same line:
#
#   permission prompt Edit: Claude requested permissions to edit
#     …/.worktrees/batch-20260831094838/.claude/hooks/session-start.sh
#     which is a sensitive file.
#
# Claude Code classifies `.claude/**` as sensitive and asks a human before editing it, and an
# unattended container has no human. **Seven runs, five hours, nothing landed** — while `/propose`
# and `/specificate`, which only read and open issues, kept producing proposals every hour. The
# freeze was SILENT: no Slack post, no finding, no `needs_agent`; `stalled-units` counted the unit
# as healthy because the resume beats the heartbeat before the edit, and `catchup-blocked` read 0.
# The operator found it by asking why proposals were piling up.
#
# THE FIELD ALREADY ROUTES THIS CORRECTLY, which is why it is reused rather than duplicated: the
# unit takes the `handoff` route, its pull request opens and stays open, the claim stays standing,
# the finish line is `🟡 Handoff` and a person is asked. Nothing about that route changes.
#
# DERIVED, NOT DECLARED, AND DELIBERATELY SO. A declaration would only ever cover tickets written
# after this change; the ticket that froze the loop was already in `todo/`, and so is every other
# one like it in every consuming repository. A DECLARED value always wins — an author who named a
# different reason is not overridden by this.
#
# THE TEST IS SYNTACTIC AND NARROW: a `## Key Files` entry naming `.claude/`. Prose elsewhere in
# the ticket is not read, because a ticket that MENTIONS `.claude/` while editing something else
# is common and stopping it would be worse than the defect. A repository that widens what an
# unattended agent may edit (a `permissions.allow` entry) is making its own decision and is not a
# substitute for the loop knowing — this reads the ticket, not the permission.
derived_handoff() {
    _dh_f="$1"
    awk '
        /^##[ \t]/ { inside = ($0 ~ /^##[ \t]+Key Files/) ; next }
        inside && /\.claude\// { found = 1 }
        END { exit found ? 0 : 1 }
    ' "$_dh_f" 2>/dev/null \
        && printf 'editing .claude/ needs a person: Claude Code classifies it as sensitive and an unattended run has no one to answer the prompt'
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
    _declared=$(fm_field "$_f" verification_handoff)
    if [ -n "$_declared" ]; then
        consider "$_id" "$_declared"
        return 0
    fi
    consider "$_id" "$(derived_handoff "$_f")"
}

case "$KIND" in
    mission)
        UNIT="$1"
        . "${SCRIPT_DIR}/../../mission/scripts/lib/resolve.sh"
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
