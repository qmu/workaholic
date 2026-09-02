#!/bin/sh -eu
# The CI-side ACT: delete the remote branch of a claim the oracle proves holds nothing.
#
# Usage: delete-retired-claim-branch.sh <unit-id> [--branch <branch>] [--reason <candidate_reason>]
#   --reason  which proof the candidate claims: `superseded_only` (the default, and what every
#             caller passed before 2026-09-01), `pull_request_merged`,
#             `pull_request_closed_unmerged`, or `mission_not_active` (2026-09-02 — the unit's
#             mission has ended, and that class needs a unit and refuses `no_unit_for_mission_class`
#             without one). Each is RE-DERIVED here; the flag says which question to re-ask,
#             never what the answer is.
#   --branch  required for every class but `superseded_only`, because the two pull-request
#             classes' candidates may carry NO unit at all: a publish-tree publication has no
#             `Claim` commit, so the oracle names no unit for it and `<unit-id>` is empty.
#             Refused `no_branch` when absent.
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
#
# TWO FURTHER CANDIDATE CLASSES, EACH RE-DERIVED HERE (2026-09-01, mission
# `leave-only-live-work-in-the-unmerged-branch-list`). `list-retirable-claims.sh` now also names
# a branch whose own pull request MERGED, and one a person CLOSED UNMERGED. The re-derivation
# discipline above is the whole reason those classes are safe to act on at all: the candidate
# list is an input, and the gap between the list and the act is a queue and a checkout. So each
# class re-asks ITS OWN question immediately before the delete, through
# `branch-pull-request-state.sh`, and refuses by its own word:
#
#   not_merged:<state>              the candidate claimed merged; the pull request is not
#   not_closed_unmerged:<state>     the candidate claimed a closure; the pull request is not
#   pull_request_unreadable:<why>   the re-read failed — an ABSENT reading, which must send a
#                                   reader to the lookup that failed and never to a delete
#
# AND THE CLOSED-UNMERGED CLASS CARRIES ONE TERM THE OTHER TWO DO NOT. `superseded` and
# `pull_request_merged` both assert the branch's content is on the base — the first by the
# oracle's own emptiness proof, the second by definition of a merge. A HAND-CLOSED branch
# asserts nothing of the kind: closing a pull request unmerged is a person's decision about the
# branch, and the branch may still hold work found on no other ref. That is precisely what
# issue #788 measured costing ~300 lines and a documentation section, so this term fails
# **closed**:
#
#   branch_holds_work         the emptiness reading says the branch still holds work
#   emptiness_unanswerable    it could not be read — refuse, never delete on an absence
#
# The reading is `claims_branch_empty_against_base`, composed rather than re-derived; the
# recovery a `superseded` delete offers (*its content is on the base*) is FALSE for a
# hand-closed branch, and this is the term that keeps the act's own promise honest.
#
# WHICH BOUNDS APPLY TO WHICH CLASS, stated rather than left to be inferred. `release_branch`,
# `not_a_work_branch` and `pull_request_open` apply to every class and are unchanged.
# `not_on_base` is the `superseded_only` class's own term and stays there: it re-derives
# `claims_superseded` from the UNIT's artifacts, which a candidate carrying no unit does not
# have — so for the two pull-request classes the equivalent question is answered by the class's
# own proof (merged) or by the emptiness term above (closed unmerged), never by a bound that
# would silently read as satisfied because there was nothing to evaluate.
#
# `not_on_base` NOW REFUSES MORE THAN ITS NAME SAYS, AND THE NAME IS KEPT DELIBERATELY
# (2026-09-01, issue #788; re-documented 2026-09-02). Since the emptiness term joined
# `claims_superseded`, re-deriving that verdict refuses on TWO facts, not one: the unit's
# tickets are not archived on the base, OR the branch still holds content the base does not
# have. The word says only the first. It is not renamed because a refusal word is a wire
# string — it reaches `record-ci-retirement-turn.sh`'s annotations, `read-ci-retirement-record.sh`,
# `/moderate`'s `retire-blocked:<unit>:<word>` question key and its asked-once ledger, so
# renaming it would re-ask every standing question under a new key and orphan every record
# written under the old one. What it costs is this paragraph; what renaming would cost is a
# person being asked twice about a branch nothing changed about. A reader chasing `not_on_base`
# is sent here, and `branch_holds_work` / `emptiness_unanswerable` below are the SAME question
# asked where the emptiness is a gate of its own rather than the row's evidence.
#
# NO NEW TRANSPORT, NO NEW PERMISSION. It is the same REST seam run by the same executor, two
# candidate classes over.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"
. "${SCRIPT_DIR}/lib/runner-identity.sh"

GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"
PR_STATE="${SCRIPT_DIR}/branch-pull-request-state.sh"
MISSION_STATE="${SCRIPT_DIR}/claim-mission-state.sh"

unit=""
CAND_BRANCH=""
CAND_REASON=superseded_only
while [ $# -gt 0 ]; do
    case "$1" in
        --branch) CAND_BRANCH="${2:-}"; shift 2 ;;
        --reason) CAND_REASON="${2:-}"; shift 2 ;;
        --) shift ;;
        -*) shift ;;
        *) [ -n "$unit" ] || unit="$1"; shift ;;
    esac
done

case "$CAND_REASON" in
    superseded_only|pull_request_merged|pull_request_closed_unmerged|mission_not_active) ;;
    *) echo "Unknown --reason: $CAND_REASON" >&2; exit 1 ;;
esac

if [ -z "$unit" ] && [ -z "$CAND_BRANCH" ]; then
    echo 'Usage: delete-retired-claim-branch.sh <unit-id> [--branch <branch>] [--reason <candidate_reason>]' >&2
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

# --- The two pull-request classes, re-derived and bounded on their own terms ----------------
# They take this path INSTEAD OF the claim-row proof gate below, because their candidate may
# carry no unit at all — and then share the same three bounds and the same transport.
if [ "$CAND_REASON" != "superseded_only" ]; then
    [ -n "$CAND_BRANCH" ] || refuse no_branch
    BRANCH="$CAND_BRANCH"

    case "$BRANCH" in
        release/*) refuse release_branch ;;
    esac
    printf '%s' "$BRANCH" | grep -q '^work-[0-9]\{8\}-[0-9]\{6\}$' || refuse not_a_work_branch

    # A LIVE CLAIM OUTRANKS EVERY PULL-REQUEST READING, exactly as it does at the candidate
    # reader: a run may be driving a FRESH claim over a discarded predecessor, and the pull
    # request is a fact about the old work. Re-derived here rather than trusted from the list.
    ROWS=$(claims_scan "$BASE" 2>/dev/null || true)
    _dr_unit=$(printf '%s' "$ROWS" | awk -F'\t' -v b="$BRANCH" '$2 == b { print $1; exit }')
    if [ -n "$_dr_unit" ]; then
        [ -n "$unit" ] || unit="$_dr_unit"
        _dr_res=$(claims_unit_resolution "$ROWS" "$_dr_unit")
        _dr_verdict=$(printf '%s' "$ROWS" | awk -F'\t' -v b="$BRANCH" '$2 == b { print $7; exit }')
        if [ "$CAND_REASON" = "mission_not_active" ]; then
            # THE MISSION CLASS RE-DERIVES THE READER'S OWN BOUND, WHICH IS NARROWER THAN THIS
            # ONE AND NOT A LOOSENING OF IT (2026-09-02). The two pull-request classes exist for
            # branches the oracle holds NO row for, so for them any row at all is a live claim
            # beating a fact about old work. This class is enumerated FROM the rows — a claim
            # branch always has one — so refusing every row would make it unreachable by
            # construction. What it refuses instead is exactly what the reader refuses:
            # `live` and `ambiguous` (another claim governs) and a `claim_active` verdict (a run
            # is driving this branch right now, which is the one loss that cannot be recovered).
            case "$_dr_res" in
                single) [ "$_dr_verdict" != "claim_active" ] || refuse "not_superseded:${_dr_verdict}" ;;
                *)      refuse "not_superseded:${_dr_verdict:-$_dr_res}" ;;
            esac
        else
            case "$_dr_res" in
                live | single | ambiguous) refuse "not_superseded:${_dr_verdict}" ;;
            esac
        fi
    elif [ "$CAND_REASON" = "mission_not_active" ]; then
        # No row at all means no claim, so there is no unit for this class to re-derive from.
        refuse no_unit_for_mission_class
    fi

    [ -f "$PR_STATE" ] || refuse pull_request_unreadable:no_reader_script
    _dr_pr=$(sh "$PR_STATE" "$BRANCH" 2>/dev/null || true)
    if [ "$(printf '%s' "$_dr_pr" | jq -r '.ok // false' 2>/dev/null || printf 'false')" != "true" ]; then
        refuse "pull_request_unreadable:$(printf '%s' "$_dr_pr" \
            | jq -r '.reason // "unreadable"' 2>/dev/null || printf 'unreadable')"
    fi
    _dr_state=$(printf '%s' "$_dr_pr" | jq -r '.state // ""' 2>/dev/null || printf '')

    if [ "$CAND_REASON" = "mission_not_active" ]; then
        # THE FOURTH CLASS, RE-DERIVED AT THE MOMENT OF THE ACT (2026-09-02, mission
        # `retire-a-claim-whose-work-is-finished-or-abandoned`). The proof is that `close.sh`
        # — the only writer of a mission's end state — moved this unit's mission into
        # `missions/archive/`: a person's recorded decision that the work is finished or is
        # not wanted, which cannot become false by looking again.
        #
        # AN OPEN PULL REQUEST IS STILL REFUSED, and the bound is NOT widened for this class.
        # Deleting the head branch of an open pull request leaves it unmergeable by anybody
        # forever — the headless shape measured on #813, #799, #688, #635 and #625, every one
        # of which a person had to close by hand. The existing `pull_request_open` gate below
        # covers it, and the candidate reader declines to offer such a branch at all.
        [ -n "$unit" ] || refuse no_unit_for_mission_class
        [ -f "$MISSION_STATE" ] || refuse mission_unreadable:no_reader_script
        _dr_ms=$(sh "$MISSION_STATE" "$unit" 2>/dev/null || true)
        if [ "$(printf '%s' "$_dr_ms" | jq -r '.ok // false' 2>/dev/null || printf 'false')" != "true" ]; then
            refuse "mission_unreadable:$(printf '%s' "$_dr_ms" \
                | jq -r '.reason // "unreadable"' 2>/dev/null || printf 'unreadable')"
        fi
        _dr_mstate=$(printf '%s' "$_dr_ms" | jq -r '.state // ""' 2>/dev/null || printf '')
        [ "$_dr_mstate" = "not_active" ] || refuse "mission_still_active:${_dr_mstate:-unknown}"
        # THE TERM THAT FAILS CLOSED, for `pull_request_closed_unmerged`'s own reason: a
        # mission's end state is a decision about the WORK and asserts nothing about what this
        # BRANCH holds. Issue #788 measured what assuming otherwise costs.
        case "$(claims_branch_empty_against_base "$BASE" "origin/${BRANCH}")" in
            true)  ;;
            false) refuse branch_holds_work ;;
            *)     refuse emptiness_unanswerable ;;
        esac
    elif [ "$CAND_REASON" = "pull_request_merged" ]; then
        [ "$_dr_state" = "merged" ] || refuse "not_merged:${_dr_state:-unknown}"
    else
        [ "$_dr_state" = "closed_unmerged" ] || refuse "not_closed_unmerged:${_dr_state:-unknown}"
        # THE TERM THAT FAILS CLOSED. A hand-closed branch asserts nothing about the base, so
        # the emptiness reading is a GATE here rather than the evidence it is on the candidate
        # row — and an absence refuses, which is the direction issue #788 turned `superseded`.
        case "$(claims_branch_empty_against_base "$BASE" "origin/${BRANCH}")" in
            true)  ;;
            false) refuse branch_holds_work ;;
            *)     refuse emptiness_unanswerable ;;
        esac
    fi

    # `pull_request_open` cannot be reached from here — an open pull request already refused
    # above by its own class word — but the bound is re-asserted rather than assumed away,
    # for the reason the `not_on_base` re-derivation gives: the cost of the redundant check is
    # a string compare and the cost of its absence is an unattended delete.
    if [ ! -f "$GH_REST" ] || ! sh "$GH_REST" available 2>/dev/null | grep -q '"ok": true'; then
        refuse gh_unavailable
    fi
    SLUG=$(sh "$GH_REST" slug 2>/dev/null || true)
    [ -n "$SLUG" ] || refuse slug_unresolved
    OWNER=${SLUG%%/*}
    _dr_open=$(sh "$GH_REST" api \
        "repos/${SLUG}/pulls?head=${OWNER}:${BRANCH}&state=open&per_page=1" 2>/dev/null || true)
    [ -z "$(printf '%s' "$_dr_open" | jq -r '.[0].number // ""' 2>/dev/null || printf '')" ] \
        || refuse pull_request_open

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
fi

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
