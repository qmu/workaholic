#!/bin/sh -eu
# What did the CI retirement turn attempt, and what did each act answer?
#
# Usage: record-ci-retirement-turn.sh --candidates <path> [--acts <path>]
#   --candidates  `list-retirable-claims.sh`'s JSON document
#   --acts        zero or more `delete-retired-claim-branch.sh` JSON documents, one per line
# Output: the workflow-command lines that ARE the record, on stdout. Always exit 0.
#
# WHY IT EXISTS (2026-08-29, mission `read-back-whether-the-loop-s-own-act-took-effect`).
# The CI executor already produced everything a later tick needs — the candidate reading with its
# own `ok`/`reason`, and one `{deleted, unit, branch, state, reason}` per candidate — and put it
# ONLY IN A JOB LOG. The job log is reachable from the loop's container through nothing: the REST
# logs endpoint answers with a redirect to signed blob storage and the fetch fails (measured
# 2026-08-29 against this repository's own run). So the verdict was written where no reading
# could consult it, and `ci-retirement-turn.sh` was left inferring `taken` from a completed run's
# EXISTENCE — which produced, hour after hour, the sentence *"ci_turn: taken so CI could not take
# the delete either"* over three branches CI had never attempted.
#
# THE SURFACE IS A CHECK-RUN ANNOTATION, and the choice was measured rather than argued:
#
#   the job log                  a signed blob redirect the container cannot follow. Not a
#                                candidate — it is what exists today, and it is the defect.
#   `$GITHUB_STEP_SUMMARY`       renders in the UI and is exposed by NO REST endpoint, so a
#                                later tick cannot read it at all.
#   a check run of our own       `POST /repos/{o}/{r}/check-runs` needs `checks: write`, which is
#                                WIDER than the `contents: write` this job holds. Refused: a
#                                recording surface must not enlarge a destructive job's grant.
#   an annotation (this)         `::notice::` needs NO permission — it is a workflow command, not
#                                an API call — and lands on the check run Actions already creates
#                                for the job. `GET /repos/{o}/{r}/check-runs/{id}/annotations`
#                                answers it in FULL, with no redirect and no credential beyond
#                                the read the tick already has. Verified against this repository
#                                on 2026-08-29 before anything was written against it.
#   a commit to `main`           refused by name: the hourly-`main`-writer class this repository
#                                has already refused twice (`workaholic:ship` §7).
#
# IT RE-DERIVES NOTHING AND OWNS NO VOCABULARY. Every word it prints is copied from the document
# it was handed: the candidate reader's `ok`/`reason`, and the act's own `state`/`reason`, which
# are a closed set documented on `delete-retired-claim-branch.sh`. Translating them here would
# put a second vocabulary between the script that printed a word and the reader that must send a
# person to it. The workflow therefore keeps owning no proof logic — this is a THIRD CALL beside
# the reader and the act, never a re-reading of either.
#
# THE CANDIDATE READING IS RECORDED EVEN WHEN IT NAMED NOTHING, and that is the whole point: a
# turn that found nothing and a turn that found three and was refused are different facts, and a
# reader that cannot tell them apart is exactly what this repairs.
#
# BOUNDED, AND A TRUNCATED RECORD SAYS SO. The candidate set is unbounded in principle and
# GitHub caps annotations per job, so at most `WORKAHOLIC_CI_RECORD_MAX` (default 20) act lines
# are printed and a `truncated` line names how many were recorded out of how many there were. A
# truncated record must never read as a short one: a unit past the bound reads `unreadable` at
# the consumer, which suppresses no question — the safe direction.

set -eu

CANDIDATES=""
ACTS=""
MAX="${WORKAHOLIC_CI_RECORD_MAX:-20}"

while [ $# -gt 0 ]; do
    case "$1" in
        --candidates) CANDIDATES="${2:-}"; shift 2 ;;
        --acts) ACTS="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done

# One field of the record. The values are a closed vocabulary of unit ids, branch names and
# refusal words, so anything outside that shape is replaced rather than escaped: a stray quote or
# newline would split the annotation line the consumer parses back.
field() {
    printf '%s' "${1:-}" | tr -d '\n\r' | sed 's/[^A-Za-z0-9._:/@+-]/_/g'
}

note() {
    printf '::notice title=claim-retirement::claim-retirement %s\n' "$1"
}

ok=false
reason=unreadable
count=0
if [ -n "$CANDIDATES" ] && [ -f "$CANDIDATES" ] && jq -e . "$CANDIDATES" >/dev/null 2>&1; then
    ok=$(jq -r '.ok // false' "$CANDIDATES")
    reason=$(jq -r '.reason // ""' "$CANDIDATES")
    count=$(jq '[.candidates[]?] | length' "$CANDIDATES")
fi
note "candidates ok=$(field "$ok") reason=$(field "$reason") count=$(field "$count")"

total=0
recorded=0
if [ -n "$ACTS" ] && [ -f "$ACTS" ]; then
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        printf '%s' "$line" | jq -e . >/dev/null 2>&1 || continue
        total=$((total + 1))
        [ "$recorded" -lt "$MAX" ] || continue
        u=$(printf '%s' "$line" | jq -r '.unit // ""')
        b=$(printf '%s' "$line" | jq -r '.branch // ""')
        s=$(printf '%s' "$line" | jq -r '.state // ""')
        r=$(printf '%s' "$line" | jq -r '.reason // ""')
        note "act unit=$(field "$u") branch=$(field "$b") state=$(field "$s") reason=$(field "$r")"
        recorded=$((recorded + 1))
    done < "$ACTS"
fi

if [ "$total" -gt "$recorded" ]; then
    note "truncated recorded=$(field "$recorded") of=$(field "$total")"
fi

exit 0
