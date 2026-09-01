#!/bin/sh -eu
# Read back what one CI retirement turn recorded about itself.
#
# Usage: read-ci-retirement-record.sh <run-id>
# Output: {"ok": bool, "reason": "", "run_id": "...",
#          "candidates_ok": bool, "candidates_reason": "", "candidates_count": n,
#          "truncated": bool, "truncated_recorded": n, "truncated_of": n,
#          "acts": [{"unit": "...", "branch": "...", "state": "...", "reason": "..."}]}
#         Always exit 0 — a degraded read is an answer, and its caller says so by name.
#
# WHY IT EXISTS (2026-08-29, mission `read-back-whether-the-loop-s-own-act-took-effect`).
# `record-ci-retirement-turn.sh` writes the turn's answer as check-run annotations; this is the
# one thing that reads them back. Two scripts, one on each side of a surface, so the format is
# owned in exactly two places rather than by every consumer that wants an answer.
#
# THE PATH, AND WHY IT NEEDS NO PERMISSION THE TICK LACKS. A run's jobs carry `check_run_url`,
# and `GET /repos/{o}/{r}/check-runs/{id}/annotations` answers the annotations in full — no
# redirect, no blob storage, nothing beyond the read the tick already holds. Measured against
# this repository on 2026-08-29, beside the job-log endpoint that answers with a signed blob URL
# the loop's container cannot follow. That measurement is what chose the surface.
#
# IT OWNS NO VOCABULARY. Every value it returns was printed by the candidate reader or by
# `delete-retired-claim-branch.sh` and is copied through unchanged. A word this script invented
# would send a reader to a string no script ever printed.
#
# A TURN THAT RECORDED NOTHING IS `ok: false`, NOT AN EMPTY SUCCESS. An empty `acts` list with
# `ok: true` would be indistinguishable from a turn that considered nothing — which is exactly
# the collapse this whole mission exists to remove. So a run whose annotations carry no
# `claim-retirement` line at all answers `no_record`.
#
# IT IS A PURE READ: no file, no commit, no ref, and two bounded GitHub reads.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts//gh-rest.sh"

RUN_ID="${1:-}"

emit_err() {
    printf '{"ok": false, "reason": "%s", "run_id": "%s", "candidates_ok": false, "candidates_reason": "", "candidates_count": 0, "truncated": false, "truncated_recorded": 0, "truncated_of": 0, "acts": []}\n' \
        "$1" "$RUN_ID"
    exit 0
}

[ -n "$RUN_ID" ] || emit_err no_run_id
if [ ! -f "$GH_REST" ] || ! sh "$GH_REST" available 2>/dev/null | grep -q '"ok": true'; then
    emit_err gh_unavailable
fi
SLUG=$(sh "$GH_REST" slug 2>/dev/null || true)
[ -n "$SLUG" ] || emit_err slug_unresolved

jobs=$(sh "$GH_REST" api "repos/${SLUG}/actions/runs/${RUN_ID}/jobs?per_page=30" 2>/dev/null || true)
[ -n "$jobs" ] || emit_err jobs_unreadable
printf '%s' "$jobs" | jq -e 'has("jobs")' >/dev/null 2>&1 || emit_err jobs_unparseable

# The check run a job's annotations hang from. Taken off the job rather than searched for by
# name: the job already names its own check run, and matching on a job name would break the
# moment the workflow renames one.
check_ids=$(printf '%s' "$jobs" \
    | jq -r '[.jobs[]? | .check_run_url // ""] | .[] | select(. != "") | sub(".*/check-runs/"; "")' \
        2>/dev/null || true)
[ -n "$check_ids" ] || emit_err no_check_run

# The record's own lines, gathered across every job of the run. `record-ci-retirement-turn.sh`
# writes them with a leading marker inside the MESSAGE as well as in the annotation title, so
# this parse does not depend on either alone surviving the round trip.
lines=""
for id in $check_ids; do
    ann=$(sh "$GH_REST" api "repos/${SLUG}/check-runs/${id}/annotations?per_page=100" 2>/dev/null || true)
    [ -n "$ann" ] || continue
    got=$(printf '%s' "$ann" \
        | jq -r '.[]? | .message // ""' 2>/dev/null \
        | sed -n 's/^claim-retirement //p' || true)
    [ -n "$got" ] || continue
    lines="${lines}${got}
"
done

[ -n "$(printf '%s' "$lines" | tr -d '[:space:]')" ] || emit_err no_record

field() { printf '%s' "$1" | sed -n "s/.*[[:space:]]$2=\([^[:space:]]*\).*/\1/p" | head -1; }

cand_line=$(printf '%s' "$lines" | grep '^candidates ' | head -1 || true)
[ -n "$cand_line" ] || emit_err no_candidate_reading
cand_ok=$(field " $cand_line" ok)
cand_reason=$(field " $cand_line" reason)
cand_count=$(field " $cand_line" count)
case "$cand_ok" in true|false) ;; *) cand_ok=false ;; esac
case "$cand_count" in ''|*[!0-9]*) cand_count=0 ;; esac

trunc_line=$(printf '%s' "$lines" | grep '^truncated ' | head -1 || true)
trunc=false; trunc_rec=0; trunc_of=0
if [ -n "$trunc_line" ]; then
    trunc=true
    trunc_rec=$(field " $trunc_line" recorded)
    trunc_of=$(field " $trunc_line" of)
    case "$trunc_rec" in ''|*[!0-9]*) trunc_rec=0 ;; esac
    case "$trunc_of" in ''|*[!0-9]*) trunc_of=0 ;; esac
fi

acts=""
sep=""
IFS='
'
for line in $(printf '%s' "$lines" | grep '^act ' || true); do
    u=$(field " $line" unit); b=$(field " $line" branch)
    s=$(field " $line" state); r=$(field " $line" reason)
    [ -n "$u" ] || continue
    acts="${acts}${sep}{\"unit\": \"${u}\", \"branch\": \"${b}\", \"state\": \"${s}\", \"reason\": \"${r}\"}"
    sep=", "
done
unset IFS

printf '{"ok": true, "reason": "", "run_id": "%s", "candidates_ok": %s, "candidates_reason": "%s", "candidates_count": %s, "truncated": %s, "truncated_recorded": %s, "truncated_of": %s, "acts": [%s]}\n' \
    "$RUN_ID" "$cand_ok" "$cand_reason" "$cand_count" "$trunc" "$trunc_rec" "$trunc_of" "$acts"
exit 0
