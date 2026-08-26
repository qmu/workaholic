#!/bin/sh -eu
# Has this claim branch's work reached the base? One reader, GRAIN-AGNOSTIC, answering
# exactly that and nothing else.
#
# WHY IT EXISTS (2026-08-26, mission `tell-a-merged-claim-from-a-live-one-at-both-grains`).
# `claims_superseded` answers the same question offline, from the tickets a batch unit
# stamps — and by construction it cannot answer for a mission claim, which stamps only
# `mission.md`. A squash merge compounds it: the content reaches the base while no branch
# commit does, so `git rev-list --count base..ref` stays positive and the claim is claimed
# forever. Measured on this repository: three of five claims headed pull requests #521,
# #537 and #546, all merged, all mission units, one of them offered `resumable: true` five
# days after its own pull request merged.
#
# THE QUESTION IS ASKED OF THE PULL REQUEST, NOT OF THE TREE. "Is there a MERGED pull
# request whose head is this branch?" answers at both grains without reading a single
# artifact — no `mission:` relation, no ticket, no `## Acceptance`. That constraint is the
# whole reason this reader is worth having: the alternative, walking every ticket on the
# base and reading its many-valued `mission:` relation, is a second parser of a field this
# repository deliberately keeps behind one reader.
#
# IT IS THREE-VALUED, AND THE THIRD VALUE IS THE POINT. `merged` and `not_merged` are facts
# about the repository; `unanswerable` is a fact about US — no `gh`, a refused transport, a
# rate limit, a response we could not parse. Collapsing that third case into `not_merged`
# would turn every offline run into a confident "still claimed", which is precisely the
# failure the claim protocol's own reader spends its longest comment refusing. A caller
# keeps its offline verdict when the answer is `unanswerable`.
#
# IT EXITS 0 IN EVERY CASE, INCLUDING EVERY DEGRADATION. A reader that exits non-zero turns
# a degraded read into a failed scan, and a failed scan reports no claims at all — the one
# outcome worse than an over-reported claim.
#
# WHY IT IS EXECUTED RATHER THAN SOURCED, against the `lib/` convention beside it
# (`claims.sh` is sourced, never run). This is the claim protocol's ONE network read, and
# keeping it a separate process is what makes it separable: a caller can decide not to spend
# it, a test can stub `gh` on PATH and drive all three states, and nothing it defines can
# leak into `claims_scan`'s variable space, which is a shell library sharing one flat
# namespace with a loop that already carries thirty `_cs_` locals. It stays in `lib/`
# because its only consumer is `claims.sh`.
#
# Usage: claim-merged.sh <branch-name>
# Output: one JSON line
#   {"branch", "state": "merged|not_merged|unanswerable", "reason"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../../gather/scripts/gh-rest.sh"

BRANCH="${1:-}"

emit() {
    printf '{"branch": "%s", "state": "%s", "reason": "%s"}\n' "$BRANCH" "$1" "${2:-}"
    exit 0
}

[ -n "$BRANCH" ] || emit unanswerable no_branch
[ -f "$GH_REST" ] || emit unanswerable no_transport_script

# NO SEPARATE AVAILABILITY PROBE. `gh-rest.sh available` would answer the same question one
# round trip earlier, and this reader runs once per claim — so the probe would double the
# network cost of the scan to learn what the call itself reports. The failure of the one
# call is classified instead, which is also the only classification that stays honest when
# the transport dies BETWEEN a probe and the call.
slug=$(sh "$GH_REST" slug 2>/dev/null || true)
case "$slug" in
    */*) ;;
    *) emit unanswerable slug_unresolved ;;
esac
owner="${slug%%/*}"

# REPOSITORY-SCOPED, AND FILTERED LOCALLY. `search/*` is refused outright by a bound
# session (`rules/shell.md`), so the lookup is the `pulls` collection narrowed by `head`,
# which the REST API supports as `<owner>:<branch>`. `state=closed` is the superset of
# merged, and `merged_at` is what separates merged from closed-unmerged — a pull request
# somebody closed without merging is emphatically NOT this branch's work reaching the base.
if ! body=$(sh "$GH_REST" api \
        "repos/${slug}/pulls?state=closed&head=${owner}:${BRANCH}&per_page=50" 2>&1); then
    # EACH FAILURE NAMED DISTINCTLY ENOUGH TO REPORT, which is what the consuming step needs
    # in order to say what it could not read rather than what it did not find.
    case "$body" in
        *"not on PATH"*) emit unanswerable gh_unavailable ;;
        *"rate limit"*|*"rate_limit"*|*"API rate"*) emit unanswerable rate_limited ;;
        *"not enabled for this session"*|*"not permitted for this session"*)
            emit unanswerable session_refused ;;
        *) emit unanswerable transport_error ;;
    esac
fi

# An unparseable body is ours too: it is never evidence that nothing merged.
printf '%s' "$body" | jq -e 'type == "array"' >/dev/null 2>&1 || emit unanswerable unparseable_response

merged=$(printf '%s' "$body" | jq '[.[] | select(.merged_at != null)] | length' 2>/dev/null || echo "")
case "$merged" in
    ''|*[!0-9]*) emit unanswerable unparseable_response ;;
esac

if [ "$merged" -gt 0 ]; then
    emit merged ""
else
    emit not_merged ""
fi
