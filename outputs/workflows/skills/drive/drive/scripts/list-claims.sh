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
# `resume_reason` is never empty: `heartbeat_lapsed` (resumable), `claim_active`,
# `foreign_identity`, `identity_unresolved`, `shallow_history`, or `queue_drained`.
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
# `stale: true` is a REPORT, never an action. Nothing here breaks a claim.
#
# `resumable` IS ALSO A REPORT HERE -- this script takes nothing over. It exists so an
# operator can read a unit's recoverability, and the reason it is not recoverable,
# WITHOUT running a survey or a takeover: `claim_active` says a run is still working it,
# `queue_drained` says the unit FINISHED and is waiting on a human (its PR), not on a
# runner, `foreign_identity` says it is not this runner's to take at any age, and
# `identity_unresolved` says this checkout cannot say who it is. Acting on the verdict is
# claim.sh's `resume` path.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
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
# AFTER the fetch: claims_fetch deepens when it can, so this reports the state the scan
# below actually ran against rather than the one the container started in.
shallow=$(claims_shallow)
base=$(claims_base)

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

printf '{"fetched": %s, "shallow": %s, "stale_hours": %s, "heartbeat_stale_minutes": %s, "base": "%s", "claims": [%s]}\n' \
    "$fetched" "$shallow" "$stale_hours" "$heartbeat_minutes" "$base" "$claims"
