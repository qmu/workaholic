#!/bin/sh -eu
# What is an `awaiting_verification` claim actually waiting on? The declared reason, in the
# words the ticket wrote it in, plus the coordinates of the pull request a person must open.
#
# WHY THIS READING EXISTS (2026-08-27, mission
# `ask-for-the-one-act-a-declared-handoff-is-waiting-on`). `list-claims.sh` already carries
# `declared_handoff` on every row -- but only as a BOOLEAN. The question a person must be asked
# names the declared reason verbatim ("an API token and account id must be added as repository
# secrets"), and that string was nowhere on the row: the scan computed it inside
# `claims_declared_handoff` and threw it away. A boolean tells somebody that a unit is waiting;
# only the string tells them what for.
#
# WHERE THE RESOLUTION LIVES, AND WHY IT IS HERE RATHER THAN ON THE ROW (the ticket required
# this choice recorded). Putting the reason on every claim row is the tempting shape and is
# refused: `stalled-units`, `undelivered-units` and `retire-claims` all read `list-claims.sh`
# and none of them wants the string, so every reader of the oracle would pay a tip read for a
# value three of the four never use. This resolves it PER CANDIDATE instead -- only for the rows
# a consumer is actually going to ask about -- which is one extra tip read per standing handoff
# and none at all on a repository that has none.
#
# `../verification-handoff.sh` STAYS THE ONE READER OF THE FIELD. Nothing here parses
# `verification_handoff:`; the blobs are materialised from the branch tip and handed to that
# reader by `claims_declared_reason`, which is the same derivation `claims_declared_handoff`
# reads for its boolean. One materialisation, one parser, two readings of it.
#
# THE REASON IS READ OFF THE WORK STILL QUEUED, NEVER THE ARCHIVED WORK -- exactly as the oracle
# reads it (`lib/claims.sh`, `claims_remaining_tickets`), so the two answers cannot diverge and
# the reading RELEASES ITSELF once that ticket is driven, with nothing stored anywhere.
#
# THE PULL REQUEST COSTS ONE LOOKUP AND THE LOOKUP IS THREE-VALUED. `claim-merged.sh` is the
# claim protocol's one network read; an `unanswerable` read leaves the coordinates UNSTATED and
# keeps the finding -- the unit is waiting on a person whether or not we could name its URL,
# which the oracle established offline. Pass `--no-lookup` to skip the call entirely.
#
# EVERY DEGRADATION IS NAMED RATHER THAN RENDERED AS A CALM `false`. An absent branch ref, an
# empty artifact list, a missing reader, a declaration that resolved to an empty string: each is
# reported in `degraded[]` by name, because a candidate emitted with a blank reason would ask a
# person to satisfy a verification nobody named.
#
# Usage: declared-handoff-detail.sh <branch> [<claimed-artifact>...] [--no-lookup]
#        The artifacts are the BASE-side paths `list-claims.sh` reports on the row; they are
#        resolved to their tip paths here, since driving a ticket is precisely a rename out of
#        todo/ and "still queued" is only a question in the tip's coordinate space.
# Output: one JSON line
#   {"branch", "handoff": bool, "reason": "<verbatim>", "pull_request": "<url>",
#    "pr_number": <n>|null, "open_hours": <n>|null, "lookup": "merged|not_merged|unanswerable|skipped",
#    "lookup_reason": "", "degraded": ["..."]}
#
# Pure read: it inspects refs and calls one REST read. It writes nothing.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

BRANCH=""
LOOKUP=1
ARTS=""
for a in "$@"; do
    case "$a" in
        --no-lookup) LOOKUP=0 ;;
        *)
            if [ -z "$BRANCH" ]; then
                BRANCH="$a"
            elif [ -z "$ARTS" ]; then
                ARTS="$a"
            else
                ARTS="${ARTS},${a}"
            fi
            ;;
    esac
done

DEGRADED=""
dsep=""
degrade() {
    DEGRADED="${DEGRADED}${dsep}\"$1\""
    dsep=", "
}

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

emit() {
    printf '{"branch": "%s", "handoff": %s, "reason": "%s", "pull_request": "%s", "pr_number": %s, "open_hours": %s, "lookup": "%s", "lookup_reason": "%s", "degraded": [%s]}\n' \
        "$(json_escape "$BRANCH")" "$1" "$(json_escape "$2")" \
        "$(json_escape "${3:-}")" "${4:-null}" "${5:-null}" "${6:-skipped}" "${7:-}" "$DEGRADED"
    exit 0
}

[ -n "$BRANCH" ] || { degrade no_branch; emit false ""; }

REF="origin/${BRANCH}"
git rev-parse --verify --quiet "$REF" >/dev/null 2>&1 || { degrade no_branch_ref; emit false ""; }

# An empty artifact list is not a declaration and must not read as one -- the same rule
# `claims_declared_handoff` keeps, named here instead of collapsing into a quiet `false`.
[ -n "$ARTS" ] || { degrade no_artifacts; emit false ""; }

[ -f "${SCRIPT_DIR}/verification-handoff.sh" ] || { degrade no_handoff_reader; emit false ""; }

# The tip coordinates. `claims_resolve_at_tip` is the scan's own resolution: the path itself when
# it still exists at the tip, and the by-filename fallback for a ticket that was renamed out of
# todo/ -- a below-threshold rename is not a deleted artifact and must not read as one.
TIP=""
tsep=""
old_ifs="$IFS"
IFS=','
for p in $ARTS; do
    at_tip=$(claims_resolve_at_tip "$REF" "$p" "$p")
    TIP="${TIP}${tsep}${at_tip}"
    tsep=","
done
IFS="$old_ifs"

# ONE walk of the still-queued set, shared by both readings below, so this can never answer from
# a different ticket set than the oracle did.
REMAINING=$(claims_remaining_tickets "$REF" "$TIP")
HANDOFF=$(claims_declared_handoff "$REF" "$TIP" "$REMAINING")
REASON=$(claims_declared_reason "$REF" "$TIP" "$REMAINING")

if [ "$HANDOFF" != "true" ]; then
    degrade not_declared
    emit false ""
fi
# The reader sets `handoff` true only on a non-empty value, so this cannot fire from the reader's
# own rule -- it is the backstop against a reading that arrived truncated, and it is named rather
# than passed on as a blank string a person cannot act on.
[ -n "$REASON" ] || degrade reason_empty

if [ "$LOOKUP" -eq 0 ]; then
    emit "$HANDOFF" "$REASON"
fi

reader="${SCRIPT_DIR}/claim-merged.sh"
[ -f "$reader" ] || { degrade no_merged_reader; emit "$HANDOFF" "$REASON"; }

look=$( sh "$reader" "$BRANCH" 2>/dev/null || true )
[ -n "$look" ] || { degrade merged_lookup_unreadable; emit "$HANDOFF" "$REASON"; }

field() {
    printf '%s' "$look" | sed -n 's/.*"'"$1"'": "\([^"]*\)".*/\1/p'
}
num() {
    _n=$(printf '%s' "$look" | sed -n 's/.*"'"$1"'": \([0-9null]*\).*/\1/p')
    case "$_n" in
        ''|*[!0-9]*) printf 'null' ;;
        *) printf '%s' "$_n" ;;
    esac
}

state=$(field state)
[ -n "$state" ] || state=unanswerable
lookup_reason=$(field reason)
pr_url=$(field pr_url)
pr_number=$(num pr_number)
open_hours=$(num open_hours)

# An `unanswerable` read leaves the coordinates unstated and KEEPS the finding: the unit is
# waiting on a declared human act whether or not we could name the pull request.
if [ "$state" = "unanswerable" ]; then
    pr_url=""
    pr_number=null
    open_hours=null
fi

emit "$HANDOFF" "$REASON" "$pr_url" "$pr_number" "$open_hours" "$state" "$lookup_reason"
