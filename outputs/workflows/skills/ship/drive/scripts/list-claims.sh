#!/bin/sh -eu
# The claim READER: report every PR-unit currently in flight, read straight out of
# git. Pure read -- it fetches and inspects refs, and writes nothing.
#
# A claim is a `Claim <unit-id>` commit on an unmerged remote branch that stamps
# `claim: <branch>` into the claimed artifacts' frontmatter (see lib/claims.sh for
# the model, and the drive SKILL's *Claims* section for the doctrine). Every runner
# calls this before picking work, so a 5-minute tick -- or a runner on another
# machine -- never double-picks a unit already being driven.
#
# Usage: list-claims.sh
# Env:   WORKAHOLIC_CLAIM_STALE_HOURS -- staleness threshold in hours (default 24)
#        WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES -- liveness window (default 30)
# Output: {"fetched": bool, "shallow": bool, "stale_hours": N,
#          "heartbeat_stale_minutes": N, "base": "<ref>", "claims": [
#            {"unit": "...", "branch": "work-...", "artifacts": ["..."],
#             "last_commit_at": "2026-...", "stale": false, "author": "...",
#             "resumable": false, "resume_reason": "claim_active"}, ...]}
# `resume_reason` is never empty: `heartbeat_lapsed`, `parked_with_pr` or
# `report_incomplete` (all resumable), `claim_active`, `foreign_identity`,
# `identity_unresolved`, `shallow_history`, or `queue_drained`.
#
# `shallow: true` means this clone's history is TRUNCATED, so "is this branch merged"
# was not answerable for every branch. lib/claims.sh deepens a shallow clone before
# scanning, so this can only stay true when origin is unreachable -- and then a claim
# may be a merged unit this reader cannot tell apart from a live one. Claims are still
# listed (over-reporting makes a runner wait; under-reporting double-picks work), but
# no `resumable` verdict is offered for an unprovable branch.
#
# `fetched: false` means origin could not be reached and the answer comes from the
# last-known remote-tracking refs. That is a DEGRADED read, not a failure: the
# reader stays useful offline, while the writer (claim.sh) refuses to claim at all
# without a reachable origin. See lib/claims.sh for why the asymmetry runs that way.
#
# `merged_lookup_unanswered` names every claim the merged-pull-request lookup could not
# answer for, with its reason (`offline`, `disabled`, `gh_unavailable`, `rate_limited`,
# `session_refused`, `transport_error`, `unparseable_response`, `slug_unresolved`,
# `no_reader_script`). It is the claim protocol's ONE network read, and this field is how the
# reader keeps its offline promise honestly: an unanswered claim keeps precisely the verdict
# it would have had without the lookup, and is NAMED here rather than rendered as a claim
# that is simply still in flight. A wrong `merged` releases work still in flight; a wrong
# `in flight` only delays a claim — so the failure direction is chosen, not accidental.
#
# `stale: true` is a REPORT, never an action. Nothing here breaks a claim.
#
# `resumable` IS ALSO A REPORT HERE -- this script takes nothing over. It exists so an
# operator can read a unit's recoverability, and the reason it is not recoverable,
# WITHOUT running a survey or a takeover: `claim_active` says a run is still working it,
# `queue_drained` says the unit FINISHED and REPORTED and is waiting on a human (its PR),
# not on a runner, `report_incomplete` says its queue is drained but it never opened a
# pull request -- a run that died between the drive and the report, whose work is pushed
# and which nobody has been told about, and which IS recoverable --, `foreign_identity`
# says it is not this runner's to take at any age, and `identity_unresolved` says this
# checkout cannot say who it is. Acting on the verdict is claim.sh's `resume` path.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo '{"error": "not inside a git repository"}' >&2
    exit 1
fi

stale_hours="${WORKAHOLIC_CLAIM_STALE_HOURS:-24}"
case "$stale_hours" in
    '' | *[!0-9]*)
        echo '{"error": "WORKAHOLIC_CLAIM_STALE_HOURS must be a non-negative integer", "got": "'"${stale_hours}"'"}' >&2
        exit 1
        ;;
esac

# Reported so the verdict below can be read against the window that produced it. The
# scan tolerates a malformed value (it must keep answering); this reader, whose whole
# job is to state the operator's view accurately, refuses one instead -- the same
# split the stale-hours check above already makes.
heartbeat_minutes="${WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES:-30}"
case "$heartbeat_minutes" in
    '' | *[!0-9]*)
        echo '{"error": "WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES must be a non-negative integer", "got": "'"${heartbeat_minutes}"'"}' >&2
        exit 1
        ;;
esac

fetched=$(claims_fetch)
# The merged lookup reads this in the parent shell: `claims_fetch` runs in a command
# substitution, so the flag it sets there dies with that subshell (see lib/claims.sh).
CLAIMS_FETCH_OK="$fetched"
# AFTER the fetch: claims_fetch deepens when it can, so this reports the state the scan
# below actually ran against rather than the one the container started in.
shallow=$(claims_shallow)
base=$(claims_base)

# THE MERGED LOOKUP'S UNANSWERED SET (2026-08-26). The scan now asks GitHub whether a claim
# branch's work reached the base through a merged pull request — the claim protocol's one
# network read — and a read it could not make must be REPORTED, never rendered as a claim
# that is simply still in flight. The scan appends `<branch>\t<reason>` here; a caller that
# does not set the variable pays nothing.
CLAIMS_UNANSWERED_FILE=$(mktemp 2>/dev/null || printf '')
export CLAIMS_UNANSWERED_FILE

claims=""
sep=""
rows=$(claims_scan "$base")
if [ -n "$rows" ]; then
    # Read the TSV the shared scan produced. `read -r` with a tab IFS keeps the
    # artifact list intact in the last field.
    while IFS='	' read -r unit branch last_at stale author resumable resume_reason reported artifacts; do
        [ -n "$unit" ] || continue
        arts=""
        asep=""
        # An empty artifact field yields no elements (the `for` sees nothing).
        old_ifs="$IFS"
        IFS=','
        for art in $artifacts; do
            arts="${arts}${asep}\"${art}\""
            asep=", "
        done
        IFS="$old_ifs"
        claims="${claims}${sep}{\"unit\": \"${unit}\", \"branch\": \"${branch}\", \"artifacts\": [${arts}], \"last_commit_at\": \"${last_at}\", \"stale\": ${stale}, \"author\": \"${author}\", \"resumable\": ${resumable}, \"resume_reason\": \"${resume_reason}\", \"reported\": ${reported}}"
        sep=", "
    done <<EOF
$rows
EOF
fi

unanswered=""
usep=""
if [ -n "$CLAIMS_UNANSWERED_FILE" ] && [ -f "$CLAIMS_UNANSWERED_FILE" ]; then
    while IFS='	' read -r ubranch ureason; do
        [ -n "$ubranch" ] || continue
        unanswered="${unanswered}${usep}{\"branch\": \"${ubranch}\", \"reason\": \"${ureason}\"}"
        usep=", "
    done < "$CLAIMS_UNANSWERED_FILE"
    rm -f "$CLAIMS_UNANSWERED_FILE"
fi

printf '{"fetched": %s, "shallow": %s, "stale_hours": %s, "heartbeat_stale_minutes": %s, "base": "%s", "merged_lookup_unanswered": [%s], "claims": [%s]}\n' \
    "$fetched" "$shallow" "$stale_hours" "$heartbeat_minutes" "$base" "$unanswered" "$claims"
