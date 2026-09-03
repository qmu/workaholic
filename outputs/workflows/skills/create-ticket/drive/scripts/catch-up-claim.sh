#!/bin/sh -eu
# Catch this identity's own claim branch up with the base, so a unit the loop already
# finished can still be delivered after the base moved under it.
#
# Usage: catch-up-claim.sh <unit-id> [base-branch]
# Output: one JSON line, ALWAYS exit 0
#   {"outcome": "caught_up"|"already_current"|"catch_up_refused", "unit": "...",
#    "branch": "...", "reason": "...", "class": "...", "conflicted_files": [...],
#    "worktree_path": "...", "merged": bool, "regenerated": bool, "validated": bool,
#    "pushed": bool,
#    "delivery": "merged"|"merge_refused: <word>"|"not_attempted[: <reason>]"}
#
# `delivery` is the pull request's fate, `outcome` is the branch's. They are two facts and are
# never collapsed: a branch can be caught up and pushed — a real repair — while the merge is
# held by a gate, refused by the transport, or not this act's to make.
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
# by design, because it LANDS a `review` unit on a present developer's ruling. This script does
# something narrower: it merges the base INTO the claim branch, pushes that branch, and — since
# 2026-09-02, on a `queue_drained` claim only — delivers the pull request the catch-up itself
# just made mergeable. The authorization it needs is the one the unit already has, and the gate
# it may not override is the one `land-unit.sh` may not either: the scan runs BEFORE the merge,
# `secret` stops it and `leak` holds the pull request open.
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
# The genuinely contested case — a hunk the MERGE ITSELF could not settle — stays a person's,
# and is reported by the caller's own run report. Since 2026-09-02
# that judgement is the WRITER's residue rather than the reader's prediction: this script
# attempts a `content`-classed branch instead of refusing before it is checked out, because the
# reader computes without the repository's `.gitattributes` and is pessimistic by construction
# against the writer (the `case "$CLASS"` block below carries the measurement).
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
#   content_conflict            the MERGE left a hunk only a person can judge — raised from the
#                               writer's own residue, never from the reader's prediction
#   not_my_claim                the claim commit's author is not this identity
#   foreign_identity            the oracle's own word for the same fact
#   identity_unresolved         this checkout cannot say who it is
#   claim_active                a run is still committing to that branch
#   dirty_worktree              uncommitted work the merge would bury
#   scan_held:<tier>            a `hard`/`confirm` finding holds the pull request — the gate
#                               WORKING, and a catch-up is not a route around it
#   pull_request_reviewed       a person has submitted a review; a push would reset it
#   reviews_unreadable:<reason> the review lookup could not be made, which is never read as
#                               "nobody has reviewed"
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
GATHER="${SCRIPT_DIR}/../../gather/scripts/"
GH_REST="${GATHER}/gh-rest.sh"
CATCHUP="${SCRIPT_DIR}/../../ship/scripts//catchup-main.sh"
MAKE_WORKTREE="${SCRIPT_DIR}/../../branching/scripts//create-mission-worktree.sh"
MERGE_REASON="${SCRIPT_DIR}/../../branching/scripts//merge-reason.sh"
SCAN="${SCRIPT_DIR}/../../release-scan/scripts//scan-branch-safety.sh"
GATE="${SCRIPT_DIR}/../../release-scan/scripts//gate-decision.sh"

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
DELIVERY="not_attempted"

json_str() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[[:cntrl:]]/ /g'
}

report() {
    # `check_log` is the path to the FAILING check's captured output, and it is empty on every
    # other exit path -- a field, not a second vocabulary. It is written only when a check went
    # red, so a caller that finds it non-empty has the bytes; a caller that finds it empty is
    # not being told the checks passed, only that none of them left a log to read.
    printf '{"outcome": "%s", "unit": "%s", "branch": "%s", "reason": "%s", "class": "%s", "conflicted_files": %s, "worktree_path": "%s", "merged": %s, "regenerated": %s, "validated": %s, "pushed": %s, "delivery": "%s", "body_source": "%s", "check_log": "%s"}\n' \
        "$1" "$(json_str "$unit")" "$(json_str "$BRANCH")" "$(json_str "${2:-}")" \
        "$(json_str "$CLASS")" "$CONFLICTED" "$(json_str "$WORKTREE")" \
        "$MERGED" "$REGENERATED" "$VALIDATED" "$PUSHED" "$(json_str "$DELIVERY")" \
        "$(json_str "${MERGE_BODY_SOURCE:-}")" "$(json_str "${CHECK_LOG:-}")"
    exit 0
}
refuse() { report catch_up_refused "$1"; }

# Declared here, beside the emitter that reads it, so every earlier refusal renders "" rather
# than tripping `set -u` on a path that never reaches the checks.
CHECK_LOG=""

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

# A `content` PREDICTION IS NOT A REFUSAL — THE WRITER DECIDES (2026-09-02, mission
# `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`). The operator's correction was
# that the tick "only spews reports and shows no sign of resolving anything", and this line was
# the mechanism: `claim-mergeability.sh` is a READER, and its `content` is a PREDICTION about
# what a merge WOULD do, made before anything is checked out. Refusing on it declined work the
# writer can actually finish.
#
# THE TWO ARE NOT MEASURING THE SAME MERGE, AND THE DIFFERENCE IS RECORDED IN THIS TREE ALREADY
# (`claim-mergeability.sh`'s own header, 2026-09-01, ticket `20260901041500`). The reader runs
# `git merge-tree` from an EMPTY DIRECTORY with `GIT_DIR` set, deliberately, so that the
# repository's own `.gitattributes` is out of reach — because GitHub applies no merge driver
# when it computes `mergeable`, and the reader's job is to predict GITHUB. The writer
# (`catchup-main.sh`) merges in a REAL CHECKOUT, where `merge=union` on the generated OKF
# indexes is in force. Measured, same git and the same two commits: from the checkout the merge
# exits 0 while the attribute-less computation exits 1 on `.workaholic/feedbacks/index.md`. So
# the reader is PESSIMISTIC BY CONSTRUCTION relative to the writer, and every branch in that gap
# was refused here without anybody ever attempting it.
#
# WHAT CHANGES IS WHERE THE REFUSAL LIVES, NOT WHETHER IT EXISTS. `content_conflict` is still
# raised, by the writer's own residue below, with nothing pushed and the branch byte-identical —
# a genuinely divergent hand-written hunk is still a person's, and `/moderate`'s
# caller's report still names it. What is gone is refusing on a guess, and the question that
# handed it to a claim holder who never comes (`catchup-blocked`, retired 2026-09-02).
#
# NOTHING ELSE IS WIDENED, and the safety story is the one this script already had:
#   * the writer auto-resolves only what its OWN proofs accept (`lib/conflict-class.sh`), so no
#     judgement moves to a machine here;
#   * a union-driver resolution is repaired, not shipped as-is — `refresh-index.sh` below
#     re-derives every generated index from the merged tree, which is the stated remedy for the
#     duplicated-or-mis-sorted line the union driver can leave;
#   * the repository's own fast checks still gate the push, and still refuse
#     `validation_failed:<check>` with nothing pushed.
#
# `unanswerable` KEEPS ITS REFUSAL. It is the ABSENCE of a reading, not a pessimistic one, and
# this repository's standing rule is that such a word is reported and never acted on
# (`reference/claims.md`, *Proofs and judgements*). Attempting on it would be acting on an
# absence, which is the failure the three-valued reading exists to avoid.
case "$CLASS" in
    unanswerable) refuse "mergeability_unanswerable:${mb_reason:-unknown}" ;;
    clean | mechanical | content) ;;
    *)            refuse "mergeability_unanswerable:${mb_reason:-unclassified}" ;;
esac

# Already current: the base is an ancestor of the branch, so there is nothing to merge and no
# ref to touch. Reported as its own outcome rather than as a no-op `caught_up`, because a run
# report that cannot tell those apart cannot tell a repair from a nothing.
case "$mb" in
    *'"already_current": true'*) report already_current "" ;;
esac

# A PULL REQUEST A PERSON HAS ALREADY REVIEWED IS LEFT ALONE (2026-08-30, mission
# `catch-a-reported-claim-up-before-its-conflict-hardens`). This is the one bound the widened
# candidate set genuinely adds, and it belongs here rather than to the reader, because this is
# where the act happens and every other bound is re-derived at the moment of the act too. An
# `undelivered` unit's pull request was refused by a TRANSPORT — nobody is looking at it. A
# `queue_drained` unit's may be one a person is MID-REVIEW on, and a push resets an approval.
#
# WHAT COUNTS AS A PERSON'S ATTENTION, decided explicitly rather than left to the seam:
#   * The reviews endpoint returns only SUBMITTED reviews — a pending review is visible to its
#     author alone — so presence in that list IS submission. No state filtering is needed to
#     exclude a draft.
#   * `APPROVED`, `CHANGES_REQUESTED`, `COMMENTED` and `DISMISSED` all count. The first two are
#     unambiguous; a `COMMENTED` review is a person writing on the diff, and a `DISMISSED` one
#     is attention that was spent and then set aside. Where the seam is ambiguous the safer
#     reading wins, and the safer reading is that somebody looked.
#   * A BOT's review is not a person's. `user.type == "Bot"` and a `…[bot]` login are both
#     filtered, because a review bot comments on every pull request the loop opens and treating
#     that as attention would refuse the whole widening.
#
# THREE-VALUED, AND THE THIRD VALUE IS THE POINT. An unreadable lookup must never read as *no
# review*: a wrong "nobody has reviewed" pushes over somebody's approval, while a wrong refusal
# only delays a unit by an hour. So every way of failing to ask answers
# `reviews_unreadable:<reason>` rather than falling through — the discipline the
# merged-pull-request lookup already records.
#
# It sits after every OFFLINE bound and before the first act, so a refusal short-circuits with
# no worktree attached and no network call spent on a question already answered locally.
[ -f "$GH_REST" ] || refuse reviews_unreadable:no_transport
# `available` exits 0 even when it answers `ok: false`, so the FIELD is what is read.
sh "$GH_REST" available 2>/dev/null | grep -q '"ok": true' || refuse reviews_unreadable:gh_unavailable
REV_SLUG=$(sh "$GH_REST" slug 2>/dev/null || true)
[ -n "$REV_SLUG" ] || refuse reviews_unreadable:slug_unresolved
REV_OWNER=${REV_SLUG%%/*}
rev_pr_json=$(sh "$GH_REST" api \
    "repos/${REV_SLUG}/pulls?head=${REV_OWNER}:${BRANCH}&state=open&per_page=1" 2>/dev/null || true)
REV_PR=$(printf '%s' "$rev_pr_json" | jq -r '.[0].number // ""' 2>/dev/null || printf '')
[ -n "$REV_PR" ] || refuse reviews_unreadable:no_open_pull_request
rev_json=$(sh "$GH_REST" api "repos/${REV_SLUG}/pulls/${REV_PR}/reviews?per_page=100" 2>/dev/null || true)
[ -n "$rev_json" ] || refuse reviews_unreadable:lookup_failed
printf '%s' "$rev_json" | jq -e 'type == "array"' >/dev/null 2>&1 \
    || refuse reviews_unreadable:lookup_unparseable
human_reviews=$(printf '%s' "$rev_json" | jq -r '
    [ .[]? | select((.user.type // "") != "Bot")
           | select(((.user.login // "") | endswith("[bot]")) | not) ] | length' 2>/dev/null || printf '')
[ -n "$human_reviews" ] || refuse reviews_unreadable:lookup_unparseable
[ "$human_reviews" = "0" ] || refuse pull_request_reviewed

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
#
# THE CHECKS RUN IN A CLEAN ENVIRONMENT, and that is not tidiness. A caller reaches this
# script through the claim protocol's own tunables — `WORKAHOLIC_CLAIM_STALE_HOURS`,
# `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES`, `WORKAHOLIC_CLAIM_MERGED_LOOKUP` — and a
# repository's test suite may legitimately assert on their DEFAULTS. Measured on this
# script's own first live run: a caller collapsing the heartbeat window (the same relaxation
# `retry-undelivered.sh --own-tip` performs) turned 16 claim-protocol assertions red, so the
# push was refused `validation_failed:test-workflow-scripts.mjs` over a branch whose suite
# passed. Unsetting them is the narrow fix: the tunables belong to the claim reading, which
# is already done by this point, and never to the repository's own verification.
# A REFUSAL THAT DISCARDS THE OUTPUT CANNOT BE DIAGNOSED, AND THIS ONE HAD TO BE
# (2026-09-03). `>/dev/null 2>&1` threw away the only evidence of WHY a check went red, so a
# refusal read `validation_failed:test-workflow-scripts.mjs` and nothing else — the same six
# words whether the branch is genuinely broken, the environment leaked (the case the note above
# records), or the run was simply unlucky. Measured here: two consecutive catch-ups on
# `work-20260902-043932` refused over that suite, and re-running the script's OWN invocation
# byte-for-byte in the same worktree answered `6236 passed, 0 failed`, exit 0, twice. Nothing
# distinguished a real failure from that, because nothing was kept.
#
# Under the loop's subagents this stopped being rare: several runs share the multi-minute suite
# on one machine, so a check can lose to load in a way no single-session premise ever showed.
#
# THE OUTPUT IS KEPT, NOT PRINTED. It goes to a file beside the worktree whose path rides the
# refusal, so stdout stays the one JSON line every caller parses and a reader is sent to the
# bytes rather than to a guess. The gate itself does not move: the same three checks, the same
# clean environment, the same refusal with nothing pushed. What changes is only that the next
# occurrence can be read.
if command -v node >/dev/null 2>&1; then
    for check in build-plugins/verify.mjs build-plugins/validate-metadata.mjs \
                 test-workflow-scripts.mjs; do
        [ -f "${WORKTREE}/scripts/${check}" ] || continue
        _cul="${WORKTREE}/../.catch-up-check-${check##*/}.log"
        ( cd "$WORKTREE" \
          && unset WORKAHOLIC_CLAIM_STALE_HOURS WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES \
                   WORKAHOLIC_CLAIM_MERGED_LOOKUP \
          && node "scripts/${check}" ) >"$_cul" 2>&1 \
            || { CHECK_LOG="$_cul"; refuse "validation_failed:${check##*/}"; }
        rm -f "$_cul"
    done
fi
VALIDATED=true

# --- Push. Never a force, never an amend, never a rebase -----------------------------
git -C "$WORKTREE" push --quiet origin "HEAD:refs/heads/${BRANCH}" >/dev/null 2>&1 \
    || refuse push_failed
PUSHED=true

# --- Deliver what this act just made mergeable ---------------------------------------
# RESOLVING AND STOPPING THERE IS THE STAGNATION THE OPERATOR NAMED (2026-09-02, mission
# `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`, ticket
# `20260902042630-let-the-tick-merge-what-it-resolved`). This script's header used to say it
# "lands nothing", and that was true and was the defect: it brought a branch back onto the base,
# pushed it, and left the pull request open for a claim holder who never comes. A parked pull
# request reads as progress to the loop and as stagnation to its operator.
#
# IT DELIVERS ONLY A `queue_drained` CLAIM, AND THE BOUND IS OWNERSHIP OF THE ACT, NOT CAUTION.
# A `report_undelivered` unit's delivery already belongs to `retry-undelivered.sh`, which
# `/implement` runs immediately after a `caught_up` (`workaholic:drive` §6). Merging here too
# would make two attempts at one pull request in one turn, and the second would answer on an
# already-merged pull request — reported as `merge_refused` and withholding `ok` from a run that
# had in fact delivered. One act owns one delivery.
#
# NO GATE IS OVERRIDDEN AND NO NEW VOCABULARY IS INVENTED. The scan runs BEFORE the merge and is
# read through `gate-decision.sh`'s severity tier, never the binary verdict: `secret` is a hard
# stop, `leak` holds the pull request open, and only the `override_only` granularity nudge lets
# a delivery through — the `review` route's own rule, unchanged. The outcome words are
# `merge-reason.sh`'s own.
#
# A DELIVERY THIS ENVIRONMENT COULD NOT ATTEMPT IS NEVER A REFUSAL OF THE CATCH-UP. The branch
# IS caught up and pushed; that is a real repair and it is reported as one. So a missing
# transport, an unresolved slug, an unreadable gate or a held gate all report `caught_up` with
# the reason on `delivery`, exactly as the publication act does.
[ "$VERDICT" = "queue_drained" ] || report caught_up ""

if [ -f "$SCAN" ] && [ -f "$GATE" ]; then
    gate="$( ( cd "$WORKTREE" && sh "$SCAN" "origin/${base}" 2>/dev/null || printf '' ) \
             | sh "$GATE" 2>/dev/null || printf '')"
    if [ -z "$gate" ]; then
        DELIVERY="not_attempted: scan_unreadable"
        report caught_up ""
    fi
    case "$gate" in
        *'"decision": "pass"'*) ;;
        *'"override_only": true'*) ;;
        *'"overridable": false'*) DELIVERY="not_attempted: scan_held:hard"; report caught_up "" ;;
        *'"decision": "block"'*)  DELIVERY="not_attempted: scan_held:confirm"; report caught_up "" ;;
        *) DELIVERY="not_attempted: scan_unreadable"; report caught_up "" ;;
    esac
fi

sh "$GH_REST" available >/dev/null 2>&1 \
    || { DELIVERY="not_attempted: gh_unavailable"; report caught_up ""; }
slug="$(sh "$GH_REST" slug 2>/dev/null || printf '')"
[ -n "$slug" ] || { DELIVERY="not_attempted: slug_unresolved"; report caught_up ""; }
owner=${slug%%/*}
pr_json=$(sh "$GH_REST" api \
    "repos/${slug}/pulls?head=${owner}:${BRANCH}&state=open&per_page=1" 2>/dev/null || true)
PR=$(printf '%s' "$pr_json" | jq -r '.[0].number // ""' 2>/dev/null || printf '')
[ -n "$PR" ] || { DELIVERY="not_attempted: no_open_pull_request"; report caught_up ""; }

# The method is READ, never spelled — `gather/scripts/merge-method.sh` is the one derivation
# and the suite fails on a literal at a call site (`CLAUDE.md`, *Enforcement gates*).
method="$(sh "${GATHER}/merge-method.sh" 2>/dev/null || printf 'squash')"
# THE SQUASH BODY IS READ, NEVER SPELLED (2026-09-03). `gather/scripts/merge-commit-body.sh`
# is the one derivation of `commit_title` / `commit_message`; without them the forge
# concatenates every commit on the branch into the trunk's record. A composer that could not
# read still yields a fallback body, so the merge is never held on it.
# THE COMPOSER READS THE PUSHED TIP. This runs after the catch-up's own push, so the
# branch story and the commit range it reads are the ones the merge will actually squash.
body_json="$(sh "${GATHER}/merge-commit-body.sh" --branch "${BRANCH}" --number "${PR}" 2>/dev/null || printf '')"
merge_title="$(printf '%s' "$body_json" | jq -r '.title // ""' 2>/dev/null || printf '')"
merge_body="$(printf '%s' "$body_json" | jq -r '.body // ""' 2>/dev/null || printf '')"
MERGE_BODY_SOURCE="$(printf '%s' "$body_json" | jq -r '.source // "unreadable:no_composer"' 2>/dev/null || printf 'unreadable:no_composer')"
set +e
merge_resp="$(sh "$GH_REST" api "repos/${slug}/pulls/${PR}/merge" \
    --method PUT -f "merge_method=${method}" \
    -f "commit_title=${merge_title}" -f "commit_message=${merge_body}" 2>&1)"
merge_status=$?
set -e

if [ "$merge_status" -eq 0 ]; then
    DELIVERY="merged"
else
    word="$(sh "$MERGE_REASON" "$merge_resp" 2>/dev/null || printf 'merge_failed')"
    DELIVERY="merge_refused: ${word}"
fi

report caught_up ""
