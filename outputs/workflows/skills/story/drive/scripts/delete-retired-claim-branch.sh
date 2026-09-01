#!/bin/sh -eu
# The CI-side ACT: delete the remote branch of a claim the oracle proves holds nothing.
#
# Usage: delete-retired-claim-branch.sh <unit-id>
# Output: {"deleted": bool, "unit": "...", "branch": "...",
#          "state": "deleted"|"already_gone"|"failed"|"not_attempted", "reason": ""}
#         `reason` is a CLOSED VOCABULARY, empty on a delete that happened. Refusals before the
#         act: `not_a_repository`, `no_origin`, `origin_unreachable`, `no_claims`,
#         `no_such_claim`, `ambiguous_claim`, `unanswerable:<why>`, `not_superseded:<verdict>`,
#         and the four bounds — `not_a_work_branch`, `release_branch`, `not_on_base`,
#         `pull_request_open`. A transport failure is `branch_delete_failed`, the same word
#         `retire-claim.sh` uses for the same act. Degradations: `gh_unavailable`,
#         `slug_unresolved`.
#         ALWAYS EXIT 0. A refusal is an answer; the workflow reports it and is not failed by it.
#
# WHY IT EXISTS (2026-08-28, mission `finish-a-proved-retirement-where-the-write-is-permitted`).
# `retire-claim.sh` takes three acts in the container the loop runs in, and Act 2 — this one — is
# refused there by every available transport: `git push origin --delete` answers
# `RPC failed; HTTP 403` and `DELETE /repos/{owner}/{repo}/git/refs/heads/{branch}` answers
# *"Write access to this GitHub API path is not permitted through this proxy."* (measured
# 2026-08-27; `../reference/claims.md`, *When an act of the retirement is refused*). That finding
# is about the CONTAINER and remains correct there. THIS IS NOT A SECOND TRANSPORT — it is the
# same REST seam run by a DIFFERENT EXECUTOR, GitHub Actions, where `GITHUB_TOKEN` makes the
# write permitted. It is `release-note-draft.yml`'s precedent one act over.
#
# WHAT MAKES A DESTRUCTIVE ACT SAFE IS THE PROOF, AND THE PROOF IS RE-TAKEN HERE. This script
# re-runs the claim scan and re-derives the row's verdict immediately before the delete rather
# than trusting the candidate list it was handed. That is `retire-claim.sh`'s own discipline
# (`step-retire-claims.sh` reads candidates once; the writer re-proves before touching anything)
# applied across an EXECUTOR BOUNDARY, where the gap between the two reads is a queue and a
# checkout rather than a function call. The redundancy is the point.
#
# EVERY OTHER VERDICT IS REFUSED BY ITS OWN WORD. `not_superseded:<verdict>` carries the verdict
# itself, so `stale`, `queue_drained` and `claim_active` stay visible as what they are rather
# than folded into a generic denial — acting on any of them tears down work somebody is driving.
# `ambiguous_claim` and `unanswerable:<reason>` are their own refusals for the reason
# `retire-claim.sh` gives them: an ABSENT reading must send a reader to the lookup that failed,
# never to a claim that merely looks live. The unit resolves through the library's live-row rule,
# never first-match — first-match is the oldest branch, which for this shape is the dead one.
#
# AND THE ACT IS BOUNDED ON TOP OF THE PROOF, each bound refused by name:
#
#   not_a_work_branch   the branch is not `work-YYYYMMDD-HHMMSS` — the one pattern
#                       `branching/scripts/create.sh` names and `guard-git-branch.sh` enforces
#   release_branch      a `release/*` ref, which is invisible to the claim protocol and must
#                       never be reachable from here whatever else is true
#   not_on_base         the content is not on the base, re-derived from the tree through
#                       `claims_superseded` rather than read off the row's verdict word
#   pull_request_open   an OPEN pull request has this head — Act 1 closes it in the container,
#                       and a branch behind an open pull request is not one CI may delete
#
# `already_gone` IS A SUCCESS, matching Act 2's own word: a branch absent from origin needs no
# delete, so a re-run over a set already taken is a clean no-op.
#
# IT ADDS NO VERDICT WORD ANYWHERE. `superseded` gains no new meaning, `lib/claims.sh` emits
# nothing new, and the *Proofs and judgements* tables are untouched — which executor takes an
# act is a different axis from what a claim reads, exactly as `branch_delete_failed` already is.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"
. "${SCRIPT_DIR}/lib/runner-identity.sh"

GH_REST="${SCRIPT_DIR}/../../gather/scripts//gh-rest.sh"

unit="${1:-}"
if [ -z "$unit" ]; then
    echo 'Usage: delete-retired-claim-branch.sh <unit-id>' >&2
    exit 1
fi

BRANCH=""
STATE="not_attempted"

json_str() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[[:cntrl:]]/ /g'
}

report() {
    printf '{"deleted": %s, "unit": "%s", "branch": "%s", "state": "%s", "reason": "%s"}\n' \
        "$1" "$(json_str "$unit")" "$(json_str "$BRANCH")" "$STATE" "$(json_str "${2:-}")"
    exit 0
}

# A refusal reports `not_attempted`, never `failed` — `failed` is a finding about the world, and
# a gate that never ran made none. `retire-claim.sh`'s rule, kept identical here.
refuse() {
    STATE="not_attempted"
    report false "$1"
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || refuse not_a_repository
git config --get remote.origin.url >/dev/null 2>&1 || refuse no_origin
[ "$(claims_fetch)" = "true" ] || refuse origin_unreachable
# `claims_fetch` ran in a command substitution, so the flag it set died with that subshell.
# Without it the merged-pull-request lookup is skipped `offline`, and a MISSION-grain claim whose
# pull request merged would never read `superseded` here — the very verdict this acts on.
CLAIMS_FETCH_OK=true
export CLAIMS_FETCH_OK

UNANSWERED_FILE=$(mktemp 2>/dev/null || printf '')
if [ -n "$UNANSWERED_FILE" ]; then
    CLAIMS_UNANSWERED_FILE="$UNANSWERED_FILE"
    export CLAIMS_UNANSWERED_FILE
    trap 'rm -f "$UNANSWERED_FILE"' EXIT INT TERM
fi

BASE=$(claims_base)
ROWS=$(claims_scan "$BASE" 2>/dev/null || true)
[ -n "$ROWS" ] || refuse no_claims

case "$(claims_unit_resolution "$ROWS" "$unit")" in
    none)      refuse no_such_claim ;;
    ambiguous) BRANCH=$(claims_unit_live_branches "$ROWS" "$unit"); refuse ambiguous_claim ;;
esac

row=$(claims_unit_row "$ROWS" "$unit")
[ -n "$row" ] || refuse no_such_claim
BRANCH=$(printf '%s' "$row" | awk -F'\t' '{print $2}')
verdict=$(printf '%s' "$row" | awk -F'\t' '{print $7}')
artifacts=$(printf '%s' "$row" | awk -F'\t' '{print $10}')
# WHERE THIS EXECUTOR HAS NO IDENTITY OF ITS OWN, RE-DERIVE AS THE CLAIM'S OWN AUTHOR — but
# only when the committed mapping names them (2026-08-29, mission
# `make-the-two-executors-agree-about-a-proved-empty-claim`). `actions/checkout@v4` configures
# no `user.email`, so the identity gate answered `identity_unresolved` for every claim before
# `superseded` was ever consulted, and this act refused `not_superseded:identity_unresolved` on
# a unit the container proves empty — while `Claim Retirement` stayed green on every run.
#
# Bounded exactly as the candidate reader's re-derivation is, and each bound is load-bearing:
# reachable ONLY with no configured identity (a container is byte-identical), only as an author
# `gather/scripts/identity.sh` resolves (an unmapped address is never impersonated), and only
# that author's OWN row is taken, so a unit held by two branches is never read as somebody
# else's. It moves NO gate: `claim_active` still outranks `superseded` in the shared
# precedence, so a live claim reads live under every identity, and the proof gate below is
# untouched — this only lets the scan reach it.
if [ "$verdict" = "identity_unresolved" ] && runner_identity_absent; then
    _author=$(printf '%s' "$row" | awk -F'\t' '{print $5}')
    _scan_as=$(runner_identity_for_author "$_author")
    if [ -n "$_scan_as" ]; then
        _rows_as=$(WORKAHOLIC_CLAIM_IDENTITY="$_scan_as" claims_scan "$BASE" 2>/dev/null || true)
        if [ -n "$_rows_as" ]; then
            _row_as=$(claims_unit_row "$_rows_as" "$unit")
            if [ -n "$_row_as" ] \
                && [ "$(printf '%s' "$_row_as" | awk -F'\t' '{print $5}')" = "$_author" ]; then
                ROWS="$_rows_as"
                row="$_row_as"
                BRANCH=$(printf '%s' "$row" | awk -F'\t' '{print $2}')
                verdict=$(printf '%s' "$row" | awk -F'\t' '{print $7}')
                artifacts=$(printf '%s' "$row" | awk -F'\t' '{print $10}')
            fi
        fi
    fi
fi

# --- The proof gate, re-derived at the moment of the act ----------------------------------
if [ "$verdict" != "superseded" ]; then
    if [ -n "$UNANSWERED_FILE" ] && [ -f "$UNANSWERED_FILE" ] \
        && awk -F'\t' -v b="$BRANCH" '$1 == b { found = 1 } END { exit found ? 0 : 1 }' "$UNANSWERED_FILE"; then
        why=$(awk -F'\t' -v b="$BRANCH" '$1 == b { print $2; exit }' "$UNANSWERED_FILE")
        refuse "unanswerable:${why:-unreadable}"
    fi
    refuse "not_superseded:${verdict}"
fi

# --- The bounds --------------------------------------------------------------------------
case "$BRANCH" in
    release/*) refuse release_branch ;;
esac
# The literal pattern `branching/scripts/create.sh` names and `guard-git-branch.sh` enforces.
# A branch outside it was never minted by the claim protocol, whatever a row says about it.
if ! printf '%s' "$BRANCH" | grep -q '^work-[0-9]\{8\}-[0-9]\{6\}$'; then
    refuse not_a_work_branch
fi

# Re-derived rather than read back off the verdict word above, and DELIBERATELY REDUNDANT with
# it for a batch claim, whose answer comes from the tree and cannot move between two reads of one
# scan. It is not redundant at the MISSION grain: there the proof is the merged-pull-request
# lookup — a NETWORK read, and the one reading in this chain that can answer differently the
# second time it is asked. Asking it again immediately before the delete is what makes "the proof
# is re-taken where the act happens" true of both grains rather than only of the cheap one. The
# cost is one tree listing or one bounded call; the cost of its absence is an unattended delete.
# THE WORD IS `superseded`, NOT `true` (2026-09-01, issue #788). The verdict became three-valued
# so that a branch whose tickets landed while it still holds work of its own reads `stranded` and
# never reaches this delete: the proof this act rests on is *the branch is empty against the
# base*, and only `superseded` now asserts it.
if [ "$(claims_superseded "$BASE" "$artifacts" "$BRANCH" "origin/${BRANCH}")" != "superseded" ]; then
    refuse not_on_base
fi

# --- The transport ------------------------------------------------------------------------
# `available` EXITS 0 EVEN WHEN IT ANSWERS `ok: false`, so the field is what is read here.
if [ ! -f "$GH_REST" ] || ! sh "$GH_REST" available 2>/dev/null | grep -q '"ok": true'; then
    refuse gh_unavailable
fi
SLUG=$(sh "$GH_REST" slug 2>/dev/null || true)
[ -n "$SLUG" ] || refuse slug_unresolved
OWNER=${SLUG%%/*}

pr_json=$(sh "$GH_REST" api "repos/${SLUG}/pulls?head=${OWNER}:${BRANCH}&state=open&per_page=1" 2>/dev/null || true)
open_pr=$(printf '%s' "$pr_json" | jq -r '.[0].number // ""' 2>/dev/null || printf '')
[ -z "$open_pr" ] || refuse pull_request_open

if ! git rev-parse --verify --quiet "refs/remotes/origin/${BRANCH}" >/dev/null 2>&1; then
    STATE="already_gone"
    report true ""
fi

if sh "$GH_REST" api "repos/${SLUG}/git/refs/heads/${BRANCH}" --method DELETE >/dev/null 2>&1; then
    STATE="deleted"
    report true ""
fi

STATE="failed"
report false branch_delete_failed
