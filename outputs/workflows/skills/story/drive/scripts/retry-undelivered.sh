#!/bin/sh -eu
# Re-attempt the merge of a unit the loop finished and the transport refused.
#
# Usage: retry-undelivered.sh <unit-id> [--own-tip]
# Output: {"attempted": bool, "unit": "...", "branch": "...", "pull_request": "...",
#          "outcome": "...", "merge_reason": "...", "recorded": bool, "reason": "..."}
#         Always exit 0. `outcome` is §6's vocabulary verbatim: `merged` or
#         `merge_refused: <merge-reason.sh word>`, empty when nothing was attempted.
#
# WHY IT EXISTS (2026-08-27, mission `deliver-and-retire-what-the-loop-already-proved-finished`).
# `report_undelivered` (2026-08-27) names a unit the loop finished whose merge the transport
# refused. The run that attempted it retries once in-session under one named precondition, and
# NO LATER RUN EVER RETRIES: `plan-units.sh` excludes the unit `claimed_undelivered` at every
# later survey and `claim.sh resume` refuses it by its own name. So a green, finished,
# undelivered unit was delivered by nobody until a human happened to open the pull request and
# press the button. Measured 2026-08-26: four such pull requests, still open a day later, with
# `ok` reported over all of them.
#
# IT ACTS ON A PROOF AND ON NOTHING ELSE. `report_undelivered` is one of exactly two verdicts
# the claim protocol classifies as a PROOF (`../reference/claims.md`, *Proofs and judgements*):
# the refusal is recorded on the branch by the run that made the attempt, not inferred here.
# `queue_drained` is a judgement meaning *waiting on a person* and is never widened into this;
# every other verdict is refused by name below. The verdict word is read from `lib/claims.sh`,
# the one scan, and re-derived nowhere.
#
# A SCAN-HELD PULL REQUEST IS NEVER TOUCHED. A `hard` (`secret`) or `confirm` (`leak`) finding
# holding a pull request open is the gate WORKING, not the loop stopping, and this run has no
# human to override it. Such a unit cannot reach the verdict at all — its recorded outcome is
# `merge_not_attempted: <tier>`, which the verdict chain routes to `queue_drained` — and the
# gate below refuses it a second time by name anyway. Two gates for one rule is deliberate here:
# the cost of the redundant one is a string compare, and the cost of its absence is an
# unattended merge past a secret finding.
#
# WHY IT MERGES AND DRIVES NOTHING. The unit's queue is drained and every ticket is archived and
# pushed, so there is no work to do and no ticket to re-claim. A takeover would push an empty
# `Resume` commit onto a branch whose pull request is open, which is precisely the 2026-08-01
# gate — hence `resumable: false` on the row, and hence a script of its own rather than a
# resumption path. It creates no branch, no worktree and no commit of its own; the single
# outward act is one `PUT .../merge` on a pull request the loop itself opened.
#
# ONE ATTEMPT. Bounded per unit per run by construction: this script makes exactly one `PUT` and
# returns. A caller that runs it twice is making the second attempt, which is the caller's to
# justify — `/implement` runs it once per `undelivered[]` entry.
#
# THE CONNECTOR RETRY IS THE CALLER'S STEP, NOT THIS SCRIPT'S. `session_type_cannot_merge` is
# the one refusal `rules/shell.md` allows to be retried through `mcp__github__merge_pull_request`,
# and no script may call an MCP tool. So this reports the word and stops; §6's numbered step 2 is
# what makes the second attempt, with its own outcome reported. That is the same seam the
# original attempt uses, unchanged in bounds.
#
# THE NEW OUTCOME IS RECORDED ON THE BRANCH, WITHOUT A WORKTREE. A still-refused unit must keep a
# CURRENT answer to *why is this pull request still open*: the recorded word feeds the next
# survey's report and `/moderate`'s question, and a stale one sends a reader after the wrong
# transport. There is no worktree here to commit from — the unit is finished and its worktree was
# torn down or never existed in this container — so the story blob is fetched, handed to
# `record-merge-outcome.sh` (still the ONE writer of that section's format), and committed back
# with plumbing against a scratch index. Nothing is checked out, the caller's index and working
# tree are untouched, and an unchanged outcome writes nothing at all. A MERGED unit records
# nothing, because the merge releases the claim and the oracle never sees the branch again.
#
# RECORDING IS NEVER LOAD-BEARING. The merge is the deliverable; a failed record is reported
# (`recorded: false` with the reason in `reason`) and never turns a landed merge into a failure.
#
# `--own-tip` RELAXES EXACTLY ONE TERM, AND ONLY BY RE-ASKING THE SAME ORACLE (2026-08-29,
# mission `land-the-loop-s-own-work-when-the-base-moves-under-it`). `catch-up-claim.sh` merges
# the base into a stranded unit's branch and pushes -- which makes the tip fresh, so the very
# next read of the verdict answers `claim_active` and this script refuses
# `not_undelivered:claim_active`. The delivery the catch-up exists to unblock was therefore
# blocked by the catch-up itself; the fixture proved it, which is why this script changed at
# all. The flag says *this run made that tip*, and its whole effect is to re-run
# `claims_scan` with `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0`: identity, ancestry,
# supersession, the drained fork and the recorded refusal are all still the ORACLE'S OWN
# answers, unchanged and computed in one place. Nothing is re-derived here, no verdict is
# widened, and every refusal below is untouched -- a unit that is genuinely mid-drive has work
# left, so the chain answers `parked_with_pr` or `heartbeat_lapsed` and this still refuses it
# by name. Without the flag the behaviour is byte-identical to what it always was.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

GH_REST="${SCRIPT_DIR}/../../gather/scripts//gh-rest.sh"
MERGE_REASON="${SCRIPT_DIR}/../../branching/scripts//merge-reason.sh"
RECORD_OUTCOME="${SCRIPT_DIR}/../../story/scripts//record-merge-outcome.sh"

unit=""
own_tip=false
for arg in "$@"; do
    case "$arg" in
        --own-tip) own_tip=true ;;
        *) [ -n "$unit" ] || unit="$arg" ;;
    esac
done
if [ -z "$unit" ]; then
    echo 'Usage: retry-undelivered.sh <unit-id> [--own-tip]' >&2
    exit 1
fi

json_str() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[[:cntrl:]]/ /g'
}

BRANCH=""
PR=""
OUTCOME=""
MERGE_REASON_WORD=""
RECORDED=false

report() {
    printf '{"attempted": %s, "unit": "%s", "branch": "%s", "pull_request": "%s", "outcome": "%s", "merge_reason": "%s", "recorded": %s, "body_source": "%s", "reason": "%s"}\n' \
        "$1" "$(json_str "$unit")" "$(json_str "$BRANCH")" "$(json_str "$PR")" \
        "$(json_str "$OUTCOME")" "$(json_str "$MERGE_REASON_WORD")" "$RECORDED" \
        "$(json_str "${MERGE_BODY_SOURCE:-}")" "$(json_str "${2:-}")"
    exit 0
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || report false not_a_repository

# THE ORACLE'S OWN READ, through the shared library rather than a second parse of
# `list-claims.sh`'s JSON — the survey that offered this unit and the gate that acts on it must
# not be able to disagree about a verdict.
BASE="${WORKAHOLIC_BASE_BRANCH:-origin/main}"
if [ "$(claims_fetch)" = "true" ]; then
    CLAIMS_FETCH_OK=true
    export CLAIMS_FETCH_OK
fi
ROWS=$(claims_scan "$BASE" 2>/dev/null || true)
[ -n "$ROWS" ] || report false no_claims

resolution=$(claims_unit_resolution "$ROWS" "$unit")
case "$resolution" in
    none)      report false no_such_claim ;;
    ambiguous) report false ambiguous_claim ;;
esac

row=$(claims_unit_row "$ROWS" "$unit")
[ -n "$row" ] || report false no_such_claim

BRANCH=$(printf '%s' "$row" | awk -F'\t' '{print $2}')
verdict=$(printf '%s' "$row" | awk -F'\t' '{print $7}')

# THE ONE RELAXED TERM (see the header): a tip this run made is not a run in progress. The
# oracle is asked again with its liveness window collapsed, so every other term of the verdict
# is still computed in exactly one place.
if [ "$own_tip" = true ] && [ "$verdict" = "claim_active" ]; then
    ROWS=$(WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 claims_scan "$BASE" 2>/dev/null || true)
    [ -n "$ROWS" ] || report false no_claims
    case "$(claims_unit_resolution "$ROWS" "$unit")" in
        none)      report false no_such_claim ;;
        ambiguous) report false ambiguous_claim ;;
    esac
    row=$(claims_unit_row "$ROWS" "$unit")
    [ -n "$row" ] || report false no_such_claim
    verdict=$(printf '%s' "$row" | awk -F'\t' '{print $7}')
fi

# GATE 1: THE VERDICT. Only the proof reaches the merge.
[ "$verdict" = "report_undelivered" ] || report false "not_undelivered:${verdict}"

# GATE 2: THE RECORDED OUTCOME. A refusal, never a scan hold — see the header. The verdict
# chain already guarantees this, and the guarantee is cheap enough to check where the act is.
recorded_outcome=$(claims_merge_outcome "origin/${BRANCH}" "$BRANCH")
case "$recorded_outcome" in
    merge_refused*)       : ;;
    merge_not_attempted*) report false "scan_held:${recorded_outcome#merge_not_attempted: }" ;;
    "")                   report false unrecorded_outcome ;;
    *)                    report false "unrecognized_outcome:${recorded_outcome}" ;;
esac

[ -f "$GH_REST" ] || report false no_transport
# `available` exits 0 even when it answers `ok: false`, so the FIELD is what is read — the exit
# status would call an absent `gh` available and send the merge into a transport that is not there.
sh "$GH_REST" available 2>/dev/null | grep -q '"ok": true' || report false gh_unavailable

SLUG=$(sh "$GH_REST" slug 2>/dev/null || true)
[ -n "$SLUG" ] || report false slug_unresolved
OWNER=${SLUG%%/*}

# The unit's own open pull request, by head branch. A bound session refuses `search/*`, so this
# is the repository-scoped endpoint every other seam here uses (`rules/shell.md`).
pr_json=$(sh "$GH_REST" api "repos/${SLUG}/pulls?head=${OWNER}:${BRANCH}&state=open&per_page=1" 2>/dev/null || true)
PR=$(printf '%s' "$pr_json" | jq -r '.[0].number // ""' 2>/dev/null || printf '')
[ -n "$PR" ] || report false no_open_pull_request

# THE BRANCH'S OWN CHECKS ARE READ BEFORE THE RETRY (2026-09-03). `branch-checks.sh` is the one
# derivation of the gate; it refuses on `checks_red` and `checks_pending` and passes on every
# other degradation. A refusal here is recorded in the ordinary merge vocabulary and the unit
# stays `report_undelivered`, so the NEXT tick retries it -- which is exactly what this script
# is for. Nothing is re-run, held, closed or written outside the recorded outcome.
CHECK_GATE=$(sh "${SCRIPT_DIR}/branch-checks.sh" "${PR}" 2>/dev/null || printf '')
GATE_REFUSAL=""
case "$(printf '%s' "$CHECK_GATE" | jq -r '.gate // "pass"' 2>/dev/null || printf 'pass')" in
    refuse) GATE_REFUSAL=$(printf '%s' "$CHECK_GATE" | jq -r '.reason // "checks_red"' 2>/dev/null || printf 'checks_red') ;;
esac

# THE ONE OUTWARD ACT. REST, exactly as the original attempt made it -- including the method,
# which is read from the one derivation rather than spelled here (2026-09-01).
# THE SQUASH BODY IS READ, NEVER SPELLED (2026-09-03). `gather/scripts/merge-commit-body.sh`
# is the one derivation of `commit_title` / `commit_message`; without them the forge
# concatenates every commit on the branch into the trunk's record. A composer that could not
# read still yields a body (the story description when one was read, the fallback line otherwise), so the merge is never held on it.
BODY_JSON=$(sh "${SCRIPT_DIR}/../../gather/scripts//merge-commit-body.sh" --branch "${BRANCH}" --number "${PR}" 2>/dev/null || printf '')
MERGE_TITLE=$(printf '%s' "$BODY_JSON" | jq -r '.title // ""' 2>/dev/null || printf '')
MERGE_BODY=$(printf '%s' "$BODY_JSON" | jq -r '.body // ""' 2>/dev/null || printf '')
MERGE_BODY_SOURCE=$(printf '%s' "$BODY_JSON" | jq -r '.source // "unreadable:no_composer"' 2>/dev/null || printf 'unreadable:no_composer')
if [ -n "$GATE_REFUSAL" ]; then
    # The gate refused, so THE MERGE IS NOT ATTEMPTED AT ALL. The refusal is recorded in the
    # ordinary merge vocabulary below, which leaves the unit `report_undelivered` for the next
    # tick to retry once the checks conclude.
    MERGE_REASON_WORD="$GATE_REFUSAL"
else
    if merge_out=$(sh "$GH_REST" api "repos/${SLUG}/pulls/${PR}/merge" --method PUT \
            -f "merge_method=$(sh "${SCRIPT_DIR}/../../gather/scripts//merge-method.sh")" \
            -f "commit_title=${MERGE_TITLE}" -f "commit_message=${MERGE_BODY}" 2>&1); then
        OUTCOME="merged"
        report true ""
    fi
    MERGE_REASON_WORD=$(sh "$MERGE_REASON" "$merge_out" 2>/dev/null || printf 'merge_failed')
fi
OUTCOME="merge_refused: ${MERGE_REASON_WORD}"

# Record the current answer on the branch, unless it is the answer already there.
[ "$recorded_outcome" = "$OUTCOME" ] && report true outcome_unchanged
[ -f "$RECORD_OUTCOME" ] || report true no_recorder

story_path=".workaholic/stories/${BRANCH}.md"
tmp=$(mktemp -d 2>/dev/null || printf '')
[ -n "$tmp" ] || report true no_tmpdir
trap 'rm -rf "$tmp"' EXIT INT TERM

git cat-file blob "origin/${BRANCH}:${story_path}" >"${tmp}/story.md" 2>/dev/null \
    || report true no_story_blob

rec=$(sh "$RECORD_OUTCOME" "${tmp}/story.md" "$OUTCOME" 2>/dev/null || true)
printf '%s' "$rec" | grep -q '"recorded": true' || report true record_refused
printf '%s' "$rec" | grep -q '"changed": true' || report true outcome_unchanged

# Commit the one changed file onto the branch tip with plumbing: no checkout, no worktree, and
# the caller's index untouched (GIT_INDEX_FILE points the whole sequence at a scratch file).
blob=$(git hash-object -w "${tmp}/story.md" 2>/dev/null || true)
[ -n "$blob" ] || report true blob_write_failed

GIT_INDEX_FILE="${tmp}/index"
export GIT_INDEX_FILE
git read-tree "origin/${BRANCH}" 2>/dev/null || report true read_tree_failed
git update-index --add --cacheinfo "100644,${blob},${story_path}" 2>/dev/null \
    || report true update_index_failed
tree=$(git write-tree 2>/dev/null || true)
unset GIT_INDEX_FILE
[ -n "$tree" ] || report true write_tree_failed

commit=$(git commit-tree "$tree" -p "origin/${BRANCH}" -m "Record the merge outcome" 2>/dev/null || true)
[ -n "$commit" ] || report true commit_tree_failed

git push --quiet origin "${commit}:refs/heads/${BRANCH}" >/dev/null 2>&1 || report true push_failed

RECORDED=true
report true ""
