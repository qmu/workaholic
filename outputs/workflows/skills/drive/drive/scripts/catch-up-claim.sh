#!/bin/sh -eu
# Catch this identity's own claim branch up with the base, so a unit the loop already
# finished can still be delivered after the base moved under it.
#
# Usage: catch-up-claim.sh <unit-id> [base-branch]
# Output: one JSON line, ALWAYS exit 0
#   {"outcome": "caught_up"|"already_current"|"catch_up_refused", "unit": "...",
#    "branch": "...", "reason": "...", "class": "...", "conflicted_files": [...],
#    "worktree_path": "...", "merged": bool, "regenerated": bool, "validated": bool,
#    "pushed": bool}
#
# WHY IT EXISTS (2026-08-29, mission `land-the-loop-s-own-work-when-the-base-moves-under-it`).
# `retry-undelivered.sh` re-attempts the MERGE of a unit the transport refused, which is the
# right act for a refused transport and no act at all for a moved base — GitHub refuses the
# same merge every hour, forever. Nothing else looked either: `/moderate`'s `merge-conflicts`
# step reports a conflicted pull request and says in its own header that it never rebases.
# Measured 2026-08-29: 4 of 7 open pull requests conflicting with `main`, three of them units
# recorded `report_undelivered` two days earlier, with 4 active missions and 10 queued tickets
# behind them.
#
# IT IS A COMPOSITION, NOT A MERGE ENGINE. `ship/scripts/catchup-main.sh` already performs the
# merge, resolves append-only `.workaholic/` conflicts by shape and classifies the rest;
# `land-unit.sh` already composes it in exactly this order. What was missing is a caller an
# unattended run can reach — `land-unit.sh` refuses `headless_context` FIRST and unoverridably,
# by design, because it LANDS a `review` unit on a present developer's ruling. This script
# lands nothing: it merges the base INTO the claim branch and pushes that branch. The
# authorization it would need is the one the unit already has.
#
# IT NARROWS A STANDING RULE RATHER THAN REVERSING IT. `step-merge-conflicts.sh`'s header
# refuses to rebase a claim branch because "a third party rebasing it races the claim holder's
# own pushes and can strand or duplicate a unit". Both halves of that reasoning are answered
# here and neither may be quietly widened:
#   * not a third party — the claim is THIS IDENTITY'S OWN (`not_my_claim` / `foreign_identity`
#     below), and a colleague's claim is untouchable at any age exactly as before;
#   * not a rebase — it is a MERGE. Never a rebase, an amend or a force-push, on any path: a
#     merge commit keeps the claim holder's own checkout valid, which is the property a
#     history rewrite destroys.
# And the race the rule is really about is answered by `claim_active`: a run still committing
# to that branch is left alone, so the only branches touched are ones whose heartbeat lapsed.
# The genuinely contested case — a `content` conflict — stays a person's, and reaches them
# through `/moderate`'s `catchup-blocked:<unit>` question.
#
# THE VERDICT IS RE-DERIVED AT THE MOMENT OF THE ACT, never trusted from a list handed in —
# `delete-retired-claim-branch.sh`'s discipline, for its reason: the gap between the caller's
# read and this act is a survey and a drive, and a row that went stale in between must be
# refused rather than acted on from a snapshot. The unit resolves through `lib/claims.sh`'s
# LIVE-ROW rule, never first-match: a unit held by a superseded branch and a live one is what a
# fresh claim over a superseded one creates, and catching up whichever sorted first is the
# dangerous direction.
#
# EVERY REFUSAL WRITES NOTHING AND EXITS 0. Each has its own word, so a reader is sent to the
# thing that actually stopped it:
#   content_conflict            a person must judge which side keeps its behaviour
#   not_my_claim                the claim commit's author is not this identity
#   foreign_identity            the oracle's own word for the same fact
#   identity_unresolved         this checkout cannot say who it is
#   claim_active                a run is still committing to that branch
#   dirty_worktree              uncommitted work the merge would bury
#   scan_held:<tier>            a `hard`/`confirm` finding holds the pull request — the gate
#                               WORKING, and a catch-up is not a route around it
#   not_a_work_branch           the claim protocol names exactly one branch shape
#   ambiguous_claim             two live claims: reported, never picked between
#   mergeability_unanswerable:<reason>   the question could not be asked here
#   no_such_claim / no_origin / origin_unreachable / no_worktree / catchup_<class>
#   validation_failed:<check>   the repo's own fast checks went red
# The one state that is NOT byte-identical after a refusal is `validation_failed`: by then
# `catchup-main.sh` has committed the merge in the unit's own worktree. The BRANCH — the claim,
# the thing every other runner reads — is untouched, because nothing was pushed; the local
# merge is reported as `merged: true, pushed: false` rather than hidden, and it is not undone,
# because `git reset --hard` is what the failure contract's safety floor forbids outright. A
# re-run merges nothing new and re-runs the checks.
#
# IDEMPOTENT. A branch that already contains the base reports `already_current` and touches no
# ref at all — no worktree, no merge, no push.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

MERGEABILITY="${SCRIPT_DIR}/claim-mergeability.sh"
CATCHUP="${SCRIPT_DIR}/../../ship/scripts//catchup-main.sh"
MAKE_WORKTREE="${SCRIPT_DIR}/../../branching/scripts//create-mission-worktree.sh"

unit="${1:-}"
base="${2:-main}"
if [ -z "$unit" ]; then
    echo 'Usage: catch-up-claim.sh <unit-id> [base-branch]' >&2
    exit 1
fi

BRANCH=""
CLASS=""
CONFLICTED="[]"
WORKTREE=""
MERGED=false
REGENERATED=false
VALIDATED=false
PUSHED=false

json_str() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[[:cntrl:]]/ /g'
}

report() {
    printf '{"outcome": "%s", "unit": "%s", "branch": "%s", "reason": "%s", "class": "%s", "conflicted_files": %s, "worktree_path": "%s", "merged": %s, "regenerated": %s, "validated": %s, "pushed": %s}\n' \
        "$1" "$(json_str "$unit")" "$(json_str "$BRANCH")" "$(json_str "${2:-}")" \
        "$(json_str "$CLASS")" "$CONFLICTED" "$(json_str "$WORKTREE")" \
        "$MERGED" "$REGENERATED" "$VALIDATED" "$PUSHED"
    exit 0
}
refuse() { report catch_up_refused "$1"; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || refuse not_a_repository
REPO_ROOT=$(git rev-parse --show-toplevel)

git config --get remote.origin.url >/dev/null 2>&1 || refuse no_origin
[ "$(claims_fetch)" = "true" ] || refuse origin_unreachable
CLAIMS_FETCH_OK=true
export CLAIMS_FETCH_OK

# --- The claim, through the oracle's own scan --------------------------------------
ROWS=$(claims_scan "$(claims_base)" 2>/dev/null || true)
[ -n "$ROWS" ] || refuse no_such_claim

case "$(claims_unit_resolution "$ROWS" "$unit")" in
    none)      refuse no_such_claim ;;
    ambiguous) refuse ambiguous_claim ;;
esac
row=$(claims_unit_row "$ROWS" "$unit")
[ -n "$row" ] || refuse no_such_claim

BRANCH=$(printf '%s' "$row" | awk -F'\t' '{print $2}')
AUTHOR=$(printf '%s' "$row" | awk -F'\t' '{print $5}')
VERDICT=$(printf '%s' "$row" | awk -F'\t' '{print $7}')

# --- The bounds, each writing nothing -----------------------------------------------
# The claim protocol names exactly one branch shape, and `guard-git-branch.sh` enforces it
# everywhere else. Checked here too because this script pushes.
case "$BRANCH" in
    work-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) refuse not_a_work_branch ;;
esac

case "$VERDICT" in
    foreign_identity | identity_unresolved) refuse "$VERDICT" ;;
esac

# THE IDENTITY BOUND IS CHECKED TWICE, DELIBERATELY. The verdict chain answers
# `foreign_identity` first, so the comparison below is unreachable through the sanctioned
# path — and the cost of the redundant check is one string compare, while the cost of its
# absence is this script merging into a colleague's claim if the chain is ever reordered.
# `retry-undelivered.sh` makes the same trade for its scan gate, for the same reason.
ME=$(git config user.email 2>/dev/null || true)
[ -n "$ME" ] || refuse identity_unresolved
[ "$AUTHOR" = "$ME" ] || refuse not_my_claim

# A `hard` (`secret`) or `confirm` (`leak`) finding holding the pull request open is the gate
# WORKING. Catching that branch up would present a scan-held unit as ready, so it is refused by
# name — read off the branch story, offline, exactly as `retry-undelivered.sh` reads it.
case "$(claims_merge_outcome "origin/${BRANCH}" "$BRANCH")" in
    merge_not_attempted*)
        held=$(claims_merge_outcome "origin/${BRANCH}" "$BRANCH")
        refuse "scan_held:${held#merge_not_attempted: }"
        ;;
esac

# --- What the merge would do, before anything is checked out ------------------------
[ -f "$MERGEABILITY" ] || refuse no_mergeability_reader
mb=$(sh "$MERGEABILITY" "$BRANCH" "origin/${base}" 2>/dev/null || true)
[ -n "$mb" ] || refuse mergeability_unreadable
CLASS=$(printf '%s' "$mb" | sed -n 's/.*"class": "\([^"]*\)".*/\1/p')
CONFLICTED=$(printf '%s' "$mb" | sed -n 's/.*"conflicted_files": \(\[[^]]*\]\).*/\1/p')
[ -n "$CONFLICTED" ] || CONFLICTED="[]"
mb_reason=$(printf '%s' "$mb" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')

case "$CLASS" in
    unanswerable) refuse "mergeability_unanswerable:${mb_reason:-unknown}" ;;
    content)      refuse content_conflict ;;
    clean | mechanical) ;;
    *)            refuse "mergeability_unanswerable:${mb_reason:-unclassified}" ;;
esac

# Already current: the base is an ancestor of the branch, so there is nothing to merge and no
# ref to touch. Reported as its own outcome rather than as a no-op `caught_up`, because a run
# report that cannot tell those apart cannot tell a repair from a nothing.
case "$mb" in
    *'"already_current": true'*) report already_current "" ;;
esac

# LIVENESS IS CHECKED HERE, NOT EARLIER, AND THE ORDER IS THE DESIGN. `claim_active` guards
# against acting on a branch a run is still committing to -- so it must sit before the first
# act and after the one answer that is not an act. A branch that already contains the base is
# reported `already_current` whatever its liveness, because reporting a no-op protects nothing
# and refusing it would make an hourly re-run of a finished catch-up look like a failure.
[ "$VERDICT" != "claim_active" ] || refuse claim_active

# --- The worktree: attach to the published branch, never mint one --------------------
# `ensure-worktree.sh` REFUSES a name that already exists on origin (2026-08-27) rather than
# minting a local branch at HEAD that shadows it — correct, and not worked around here.
# Attaching to a published branch is `create-mission-worktree.sh --branch`'s job.
WORKTREE="${REPO_ROOT}/.worktrees/${unit}"
if [ ! -d "$WORKTREE" ]; then
    [ -f "$MAKE_WORKTREE" ] || refuse no_worktree_script
    ( cd "$REPO_ROOT" && sh "$MAKE_WORKTREE" --branch "$BRANCH" "$unit" ) >/dev/null 2>&1 \
        || refuse worktree_attach_failed
    [ -d "$WORKTREE" ] || refuse no_worktree
fi

on_branch=$(git -C "$WORKTREE" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '')
[ "$on_branch" = "$BRANCH" ] || refuse worktree_on_other_branch

[ -z "$(git -C "$WORKTREE" status --porcelain 2>/dev/null || printf 'x')" ] || refuse dirty_worktree

# --- The merge, composed and never re-derived ---------------------------------------
[ -f "$CATCHUP" ] || refuse no_catchup_script
catchup_out=$( ( cd "$WORKTREE" && sh "$CATCHUP" "$base" --resolve-mechanical ) 2>/dev/null || printf '')
case "$catchup_out" in
    *'"caught_up": true'*) MERGED=true ;;
    *'"conflict_class": "content"'*) refuse content_conflict ;;
    # A mechanical remainder the flag could not resolve is NOT re-labelled `content`: the class
    # is the writer's word and this is its own residue, so the reader is sent to the pass that
    # gave up rather than to a person who is not the right one to ask.
    *'"conflict_class": "mechanical"'*) refuse catchup_mechanical_unresolved ;;
    *'"reason": "merge_failed"'*) refuse catchup_merge_failed ;;
    *) refuse catchup_unreadable ;;
esac

# --- Regenerate with the repository's own tooling, never by hand ---------------------
# THIS IS THE OBLIGATION `--resolve-mechanical` PUT ON THIS CALLER. Every generated path the
# merge resolved by taking a side is re-derived here, so what is pushed is the merged source's
# own output rather than one branch's stale copy. Two tools, both the repository's own:
# `refresh-index.sh` for the OKF indexes and `build.mjs` for `outputs/`.
#
# Absent tooling is not a failure: a consuming repository has no `outputs/` to rebuild, and
# refusing there would make the catch-up unavailable to every repository but this one.
REFRESH_INDEX="${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh"
if [ -f "$REFRESH_INDEX" ] && [ -d "${WORKTREE}/.workaholic" ]; then
    ( cd "$WORKTREE" && sh "$REFRESH_INDEX" ) >/dev/null 2>&1 || refuse index_refresh_failed
    REGENERATED=true
fi
if [ -f "${WORKTREE}/scripts/build-plugins/build.mjs" ] && command -v node >/dev/null 2>&1; then
    ( cd "$WORKTREE" && node scripts/build-plugins/build.mjs ) >/dev/null 2>&1 \
        || refuse regeneration_failed
    REGENERATED=true
fi
if [ "$REGENERATED" = true ] \
   && [ -n "$(git -C "$WORKTREE" status --porcelain 2>/dev/null || printf '')" ]; then
    git -C "$WORKTREE" add -A >/dev/null 2>&1 || refuse regeneration_stage_failed
    git -C "$WORKTREE" commit -q -m "Regenerate the derived files" >/dev/null 2>&1 \
        || refuse regeneration_commit_failed
fi

# --- The repository's own fast checks, before the push -------------------------------
# A push that turns CI red costs a cycle and the reviewers' trust, and this push lands on a
# branch behind an open pull request. Each check is named in its own refusal so a reader is
# sent to the one that went red rather than to "validation".
if command -v node >/dev/null 2>&1; then
    for check in build-plugins/verify.mjs build-plugins/validate-metadata.mjs \
                 test-workflow-scripts.mjs; do
        [ -f "${WORKTREE}/scripts/${check}" ] || continue
        ( cd "$WORKTREE" && node "scripts/${check}" ) >/dev/null 2>&1 \
            || refuse "validation_failed:${check##*/}"
    done
fi
VALIDATED=true

# --- Push. Never a force, never an amend, never a rebase -----------------------------
git -C "$WORKTREE" push --quiet origin "HEAD:refs/heads/${BRANCH}" >/dev/null 2>&1 \
    || refuse push_failed
PUSHED=true

report caught_up ""
