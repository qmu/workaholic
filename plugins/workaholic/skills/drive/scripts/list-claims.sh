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
#             "resumable": false, "resume_reason": "claim_active",
#             "reported": false, "declared_handoff": false,
#             "mergeability": "clean"|"mechanical"|"content"|"unanswerable",
#             "mergeability_reason": ""}, ...]}
#
# `mergeability` says whether the BASE still accepts this branch, which is a different question
# from `resume_reason`'s *whose business is this claim* and was asked by nothing until
# 2026-08-29. `content` is the one value that needs a person -- a conflict the loop must not
# resolve -- and `/moderate`'s `catchup-blocked:<unit>` step is what reaches them. It is derived
# offline through `claim-mergeability.sh` (`git merge-tree`, no worktree, no ref, no network
# call this scan has not already made), and every one of its four values is a JUDGEMENT: a base
# that moves is exactly a reading that becomes false by looking again.
#
# `declared_handoff: true` means the work this claim still has QUEUED was declared
# unverifiable in an unattended environment at creation (`verification_handoff:`, read through
# the one reader that owns that field). It is reported on every row rather than only where a
# verdict forks, so a consumer never has to derive it a second time -- and it is read from the
# REMAINING work, so it answers `false` again on its own once that ticket is driven.
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
    while IFS='	' read -r unit branch last_at stale author resumable resume_reason reported declared_handoff artifacts; do
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
        # WHY THE MERGE OUTCOME IS READ HERE AND NOT CARRIED IN THE TSV (2026-08-27, mission
        # `close-the-units-the-loop-already-finished`). The scan's row has a load-bearing field
        # count -- the library's longest warning is about exactly what happens when a column is
        # added -- and this value is only ever wanted by a caller rendering the operator's view.
        # `claims_merge_outcome` is a `git cat-file` over a blob the scan already reached, so
        # reading it per row here costs no network call and adds no second derivation. Empty for
        # every claim that recorded nothing, which is every claim but an undelivered one.
        merge_outcome=$(claims_merge_outcome "origin/${branch}" "$branch")
        # WHETHER THIS BRANCH STILL MERGES, beside the verdict rather than instead of it
        # (2026-08-29, mission `land-the-loop-s-own-work-when-the-base-moves-under-it`). The
        # verdict answers *whose business is this claim*; this answers *does the base still
        # accept it*, which nothing in the loop asked -- so a unit finished and refused its
        # merge was stranded the moment the base moved and every consumer read it as simply
        # waiting. It is offline (`git merge-tree`, no worktree, no ref, no network call the
        # scan has not already made), and it is REPORTED here, never acted on: all four values
        # are judgements, and `catch-up-claim.sh` re-derives its own at the moment of its act.
        # The conflicted paths ride the row for the same reason `merge_outcome` does: the one
        # consumer that must NAME them (`/moderate`'s `catchup-blocked` question) would
        # otherwise call the reader a second time, and two reads of one fact drift.
        mergeability=unanswerable
        mergeability_reason=no_reader_script
        mergeability_content_files="[]"
        if [ -f "${SCRIPT_DIR}/claim-mergeability.sh" ]; then
            _lc_mb=$(sh "${SCRIPT_DIR}/claim-mergeability.sh" "$branch" "$base" 2>/dev/null || true)
            _lc_c=$(printf '%s' "$_lc_mb" | sed -n 's/.*"class": "\([^"]*\)".*/\1/p')
            if [ -n "$_lc_c" ]; then
                mergeability="$_lc_c"
                mergeability_reason=$(printf '%s' "$_lc_mb" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
                _lc_f=$(printf '%s' "$_lc_mb" | sed -n 's/.*"content_files": \(\[[^]]*\]\).*/\1/p')
                [ -z "$_lc_f" ] || mergeability_content_files="$_lc_f"
            else
                mergeability_reason=unreadable
            fi
        fi
        claims="${claims}${sep}{\"unit\": \"${unit}\", \"branch\": \"${branch}\", \"artifacts\": [${arts}], \"last_commit_at\": \"${last_at}\", \"stale\": ${stale}, \"author\": \"${author}\", \"resumable\": ${resumable}, \"resume_reason\": \"${resume_reason}\", \"reported\": ${reported}, \"declared_handoff\": ${declared_handoff}, \"merge_outcome\": \"${merge_outcome}\", \"mergeability\": \"${mergeability}\", \"mergeability_reason\": \"${mergeability_reason}\", \"mergeability_content_files\": ${mergeability_content_files}}"
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
