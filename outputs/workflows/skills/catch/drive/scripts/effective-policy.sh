#!/bin/sh -eu
# Derive a PR-unit's EFFECTIVE merge policy: may this unit merge automatically,
# or must it stop at a PR for a human to review?
#
#   effective-policy.sh mission <slug-or-file>
#   effective-policy.sh tickets <ticket-file>...
#
# Output: JSON
#   {"policy": "auto"|"review", "kind": "mission"|"tickets", "unit": "<id>",
#    "members": [{"id": "...", "merge_policy": "..."}], "reason": "..."}
#   reason: ""                  every member is explicitly auto
#           "review_member"     a member is explicitly review
#           "absent"            a member records no policy (the conservative default)
#           "not_found"         a member does not exist -- reported, and review
#   The offending member is named in `member` alongside the reason.
#
# THE RULE (docs/loop-engineering-workflow.md G5, amended by K2). Merge policy is
# recorded per artifact AT CREATION -- a mission's by create.sh / scaffold-draft.sh,
# a ticket's at ticket time. It used to be recorded at a mission's approval; that
# step is retired, and one creation-time rule now covers both artifact kinds. A unit
# is auto ONLY when every member says `auto`; any review member wins, and so does any
# member that says nothing.
#
# ABSENT MEANS REVIEW, AND THAT ASYMMETRY IS THE WHOLE DESIGN. The two failure
# directions are not comparable: defaulting to `review` costs a human a look at a
# PR, while defaulting to `auto` merges work nobody authorized merging. Every
# artifact predating the field -- and every hand-written one that forgot it --
# therefore lands on the reviewable side. Silence is not consent.
#
# ANY REVIEW MEMBER WINS, because the unit is one merge. Half a PR cannot merge
# automatically while the other half waits; the batch is exactly the thing the
# reviewer was promised a look at. (This is also why the executor keeps batches
# conservative: scooping an unrelated auto ticket into a review batch does not
# make it merge, it just delays it.)
#
# THIS SCRIPT ANSWERS "MAY IT MERGE", NEVER "MAY IT RUN". Authorization to
# implement is whether the mission is in flight with a plan (drive-authorized.sh);
# merge policy is the orthogonal axis, and conflating them would let an ended
# mission's `auto` policy read as permission to drive it.
#
# Pure read: it inspects frontmatter and writes nothing.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

KIND="${1:-}"
case "$KIND" in
    mission | tickets) shift ;;
    *)
        echo 'Usage: effective-policy.sh mission <slug-or-file> | effective-policy.sh tickets <ticket-file>...' >&2
        exit 1
        ;;
esac

if [ "$#" -eq 0 ]; then
    echo 'Usage: effective-policy.sh mission <slug-or-file> | effective-policy.sh tickets <ticket-file>...' >&2
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
POLICY="auto"
REASON=""
OFFENDER=""

# Record one member's verdict. The FIRST refusal is the reported one, but every
# member is still listed: a report that stopped at the first offender would hide
# the second, and the developer reading "why did this not merge" needs the set.
consider() {
    _c_id="$1"
    _c_policy="$2"
    _c_reason="$3"
    MEMBERS="${MEMBERS}${sep}{\"id\": \"$(json_escape "$_c_id")\", \"merge_policy\": \"$(json_escape "$_c_policy")\"}"
    sep=", "
    if [ -n "$_c_reason" ] && [ -z "$REASON" ]; then
        POLICY="review"
        REASON="$_c_reason"
        OFFENDER="$_c_id"
    fi
}

# Classify one artifact's recorded policy.
classify() {
    _f="$1"
    _id="$2"
    if [ ! -f "$_f" ]; then
        consider "$_id" "" "not_found"
        return 0
    fi
    _p=$(fm_field "$_f" merge_policy)
    case "$_p" in
        auto) consider "$_id" "auto" "" ;;
        review) consider "$_id" "review" "review_member" ;;
        *) consider "$_id" "$_p" "absent" ;;
    esac
}

case "$KIND" in
    mission)
        UNIT="$1"
        . "${SCRIPT_DIR}/../../mission/scripts//lib/resolve.sh"
        ROOT=$(missions_root_for_arg "$UNIT")
        FILE=$(mission_resolve "$ROOT" "$UNIT")
        # The unit id is the slug, whichever form the caller passed.
        case "$FILE" in
            */mission.md) UNIT=$(basename "$(dirname "$FILE")") ;;
        esac
        classify "$FILE" "$UNIT"
        ;;
    tickets)
        # A batch's unit id is minted by claim.sh, not here -- this script may run
        # BEFORE the claim (to decide how a unit would route) as well as after, so
        # it reports the members and leaves the id to the claim.
        UNIT="batch"
        for t in "$@"; do
            classify "$t" "$t"
        done
        ;;
esac

printf '{"policy": "%s", "kind": "%s", "unit": "%s", "members": [%s], "reason": "%s", "member": "%s"}\n' \
    "$POLICY" "$KIND" "$(json_escape "$UNIT")" "$MEMBERS" "$REASON" "$(json_escape "$OFFENDER")"
