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
# Output: {"fetched": bool, "stale_hours": N, "base": "<ref>", "claims": [
#            {"unit": "...", "branch": "work-...", "artifacts": ["..."],
#             "last_commit_at": "2026-...", "stale": false}, ...]}
#
# `fetched: false` means origin could not be reached and the answer comes from the
# last-known remote-tracking refs. That is a DEGRADED read, not a failure: the
# reader stays useful offline, while the writer (claim.sh) refuses to claim at all
# without a reachable origin. See lib/claims.sh for why the asymmetry runs that way.
#
# `stale: true` is a REPORT, never an action. Nothing here breaks a claim.

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

fetched=$(claims_fetch)
base=$(claims_base)

claims=""
sep=""
rows=$(claims_scan "$base")
if [ -n "$rows" ]; then
    # Read the TSV the shared scan produced. `read -r` with a tab IFS keeps the
    # artifact list intact in the last field.
    while IFS='	' read -r unit branch last_at stale artifacts; do
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
        claims="${claims}${sep}{\"unit\": \"${unit}\", \"branch\": \"${branch}\", \"artifacts\": [${arts}], \"last_commit_at\": \"${last_at}\", \"stale\": ${stale}}"
        sep=", "
    done <<EOF
$rows
EOF
fi

printf '{"fetched": %s, "stale_hours": %s, "base": "%s", "claims": [%s]}\n' \
    "$fetched" "$stale_hours" "$base" "$claims"
