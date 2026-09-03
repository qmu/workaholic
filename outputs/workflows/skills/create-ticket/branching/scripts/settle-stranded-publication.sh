#!/bin/sh -eu
# settle-stranded-publication.sh — BRING ONE STRANDED PUBLICATION BACK ONTO THE BASE AND
# DELIVER IT, whenever a generator settles its conflict, without a person.
#
#   settle-stranded-publication.sh <pull-request-number> [base-branch]
#
# Output: one JSON line, ALWAYS exit 0
#   {"outcome": "settled"|"already_current"|"settle_refused", "number": N, "branch": "work-…",
#    "reason": "", "class": "mechanical", "conflicted_files": [...], "worktree_path": "",
#    "merged": bool, "regenerated": bool, "validated": bool, "pushed": bool,
#    "delivery": "merged"|"merge_refused: <word>"|"not_attempted"}
#
# ═══ WHY IT EXISTS (2026-08-31, mission ══════════════════════════════════════════════
# `repair-a-mechanically-resolvable-conflict-instead-of-reporting-it`). The measured repair
# was three commands — merge the base, run `refresh-index.sh`, commit — and every one of them
# already ships here. What was missing was a caller: a publication is not a claim, so
# `catch-up-claim.sh`, whose whole subject is a claim's unit, identity and heartbeat, could
# never take one. This script is that caller and invents nothing: no merge engine, no second
# classification rule, no claim verdict word.
#
# ═══ THE FOUR TERMS OF A BOUNDED ACT (`drive/reference/claims.md`) ════════════════════
#   RE-DERIVED AT THE MOMENT OF THE ACT — the publication is resolved through
#     `list-stranded-publications.sh` here and now, never from a list handed in. The gap
#     between a caller's read and this act is a whole tick.
#   IDEMPOTENT — a publication already containing the base reports `already_current` and
#     touches no ref; a second run over a delivered one finds no open pull request and refuses
#     by name.
#   REVERSIBLE — the only writes are a MERGE commit and a push onto the publication's own
#     branch. Never a rebase, never an amend, never a force-push, never a branch deleted and
#     never a pull request closed: a merge commit keeps every existing checkout valid.
#   REFUSES EVERY BOUND BY ITS OWN WORD — each refusal below has its own, so a reader is sent
#     to the thing that actually stopped it rather than to "refused".
#
# ═══ THE REFUSALS ════════════════════════════════════════════════════════════════════
#   not_a_stranded_publication  the reader does not name this pull request — it is a claim, an
#                               operator-facing publication, closed, or not a publication
#   reader_unreadable:<reason>  the reader degraded; an absence it could not establish is never
#                               read as *nothing to settle*
#   not_mechanical:<class>      `unanswerable` is the ABSENCE of a reading — never actable.
#                               `clean`, `mechanical` and (since 2026-09-02) `content` are the
#                               accepted classes; the word is kept as it is because every report
#                               surface quotes it.
#   content_conflict            the MERGE ITSELF left a hunk only a person can judge. Since
#                               2026-09-02 this is the ONLY place a content collision refuses:
#                               the reader's prediction is attempted, the writer's residue is
#                               what stops the act.
#   has_claim_commit            the branch is a claim; the catch-up owns it, not this
#   not_a_work_branch           the publish seam mints exactly one branch shape
#   scan_held:<tier>            a `hard` (`secret`) or `confirm` (`leak`) finding holds the pull
#                               request open — the gate WORKING, and this is not a route around it
#   scan_unreadable             the gate could not be read, which is never read as `pass`
#   dirty_worktree              uncommitted work the merge would bury
#   validation_failed:<check>   the repository's own fast checks went red
#   push_failed / no_open_pull_request / gh_unavailable / no_worktree / catchup_<class>
#
# ═══ THE TWO ACCEPTED CLASSES (2026-09-01, mission ═══════════════════════════════════
# `deliver-a-stranded-publication-that-needs-nothing-but-a-merge`). `mechanical` and `clean`,
# and the difference between them is only how much has to happen BEFORE the one merge:
#
#   mechanical  the base has moved and a generator settles the collision — attach the
#               worktree, merge the base in, regenerate, run the fast checks, push, THEN the
#               gate, THEN the merge. `merged`/`regenerated`/`pushed` report true.
#   clean       nothing collides, so there is nothing to catch up: the branch is mergeable as
#               it stands and every one of those steps has nothing to do. The worktree is
#               still attached (the GATE needs a checkout of the branch to scan), and
#               `merged`, `regenerated`, `validated` and `pushed` all report FALSE, which is
#               the truth and is how a reader tells the two paths apart in the report. The
#               fast checks go with the push they guard: this branch is byte-identical to the
#               one its own CI already ran, so re-running the suite would assert nothing new.
#
# Measured 2026-09-01: five of six open publications read `clean` (#813, #799, #688, #635,
# #625), the oldest opened 2026-08-26, every one green and stranded by a race with its own CI
# — `publish-tree-pr.sh` opens the pull request and attempts the merge in the same breath,
# GitHub answers 405 before any check has started, and `merge_not_allowed` is not a word the
# caller retries. The class was read, named in the report and delivered by nothing.
#
# ═══ WHAT IT COSTS, SAID RATHER THAN LEFT TO BE NOTICED ══════════════════════════════
# On the `mechanical` path the publication's pull request gains a MERGE COMMIT from the base.
# That is exactly what `catch-up-claim.sh` already does for a claim branch, so it is consistent
# rather than new. On the `clean` path no ref is written at all before the merge attempt.
#
# ═══ NO GATE IS EVER OVERRIDDEN ══════════════════════════════════════════════════════
# The scan runs before the merge attempt and a finding refuses by its own word. A publication
# left open by the seam's own refusal (`strategy_touching`, `ruling_touching`) never reaches
# this script at all: the reader excludes it, and that boundary is stated there once.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
READER="${SCRIPT_DIR}/list-stranded-publications.sh"
GATHER="${SCRIPT_DIR}/../../gather/scripts/"
CATCHUP="${SCRIPT_DIR}/../../ship/scripts//catchup-main.sh"
MAKE_WORKTREE="${SCRIPT_DIR}/create-mission-worktree.sh"
CLEAN_WORKTREE="${SCRIPT_DIR}/cleanup-mission-worktree.sh"
MERGE_REASON="${SCRIPT_DIR}/merge-reason.sh"
SCAN="${SCRIPT_DIR}/../../release-scan/scripts//scan-branch-safety.sh"
GATE="${SCRIPT_DIR}/../../release-scan/scripts//gate-decision.sh"

NUMBER="${1:-}"
BASE_BRANCH="${2:-main}"
if [ -z "$NUMBER" ]; then
    echo 'Usage: settle-stranded-publication.sh <pull-request-number> [base-branch]' >&2
    exit 1
fi
case "$NUMBER" in
    ''|*[!0-9]*) echo 'Usage: settle-stranded-publication.sh <pull-request-number> [base-branch]' >&2; exit 1 ;;
esac

BRANCH=""
CLASS=""
AGE=null
CONFLICTED="[]"
WORKTREE=""
MERGED=false
REGENERATED=false
VALIDATED=false
PUSHED=false
DELIVERY="not_attempted"
WORKTREE_ID="publication-${NUMBER}"

json_str() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[[:cntrl:]]/ /g'
}

# THE WORKTREE IS TORN DOWN WHERE TEARING IT DOWN LOSES NOTHING, and left standing where it
# holds a local merge nobody has pushed. `cleanup-mission-worktree.sh` is the sanctioned cleaner
# — it refuses a dirty worktree rather than discarding work, and the branch it deletes is the
# LOCAL one, never the publication's remote branch and never its pull request. A refusal that
# comes after the merge (`validation_failed`, `push_failed`) keeps its worktree and reports the
# path, which is `catch-up-claim.sh`'s own contract: the merge is not undone, because
# `git reset --hard` is what the failure contract's safety floor forbids outright.
teardown_worktree() {
    case "$1" in
        settled | already_current) ;;
        *) [ "$MERGED" = false ] || return 0 ;;
    esac
    [ -n "$WORKTREE" ] && [ -d "$WORKTREE" ] || return 0
    [ -f "$CLEAN_WORKTREE" ] || return 0
    ( cd "$REPO_ROOT" && sh "$CLEAN_WORKTREE" "$WORKTREE_ID" ) >/dev/null 2>&1 || return 0
    [ -d "$WORKTREE" ] || WORKTREE=""
}

report() {
    teardown_worktree "$1"
    printf '{"outcome": "%s", "number": %s, "branch": "%s", "reason": "%s", "class": "%s", "age_hours": %s, "conflicted_files": %s, "worktree_path": "%s", "merged": %s, "regenerated": %s, "validated": %s, "pushed": %s, "delivery": "%s", "body_source": "%s"}\n' \
        "$1" "$NUMBER" "$(json_str "$BRANCH")" "$(json_str "${2:-}")" "$(json_str "$CLASS")" \
        "$AGE" "$CONFLICTED" "$(json_str "$WORKTREE")" \
        "$MERGED" "$REGENERATED" "$VALIDATED" "$PUSHED" "$(json_str "$DELIVERY")" \
        "$(json_str "${MERGE_BODY_SOURCE:-}")"
    exit 0
}
refuse() { report settle_refused "$1"; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || refuse not_a_repository
REPO_ROOT=$(git rev-parse --show-toplevel)
command -v jq >/dev/null 2>&1 || refuse jq_unavailable
[ -f "$READER" ] || refuse no_reader_script

# ── THE VERDICT, RE-DERIVED HERE AND NOW ─────────────────────────────────────────────
rows="$(sh "$READER" --base "origin/${BASE_BRANCH}" 2>/dev/null || printf '')"
[ -n "$rows" ] || refuse reader_unreadable:no_output
printf '%s' "$rows" | jq -e . >/dev/null 2>&1 || refuse reader_unreadable:unparseable
case "$rows" in
    *'"ok": false'*)
        r="$(printf '%s' "$rows" | jq -r '.reason // "unknown"' 2>/dev/null || printf 'unknown')"
        refuse "reader_unreadable:${r}"
        ;;
esac

row="$(printf '%s' "$rows" | jq -c --arg n "$NUMBER" '.publications[]? | select((.number|tostring) == $n)' 2>/dev/null || printf '')"
[ -n "$row" ] || refuse not_a_stranded_publication

BRANCH="$(printf '%s' "$row" | jq -r '.branch // ""')"
CLASS="$(printf '%s' "$row" | jq -r '.mergeability // ""')"
# THE AGE RIDES THE ROW THE VERDICT CAME FROM (2026-09-01) — re-derived here and now, because
# the reader above was re-run here and now. It is REPORTED and never read: no branch of this
# script tests it, so an old publication settles exactly as a fresh one does. What it earns is
# that the caller can say a stale plan landed; a gate here would strand the very publications
# the `clean` widening exists to deliver.
AGE="$(printf '%s' "$row" | jq -r 'if (.age_hours|type) == "number" then (.age_hours|tostring) else "null" end' 2>/dev/null || printf 'null')"
[ -n "$BRANCH" ] || refuse not_a_stranded_publication

# THE BRANCH SHAPE IS CHECKED AGAIN HERE, DELIBERATELY. The reader already applies it, so this
# is unreachable through the sanctioned path — and the cost of the redundant check is one
# pattern match, while the cost of its absence is this script pushing onto a branch the
# protocol never named. `catch-up-claim.sh` makes the same trade for its identity bound.
case "$BRANCH" in
    work-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) refuse not_a_work_branch ;;
esac

# And so is the claim term: a claim branch reaching this script would be the one act the
# narrowing forbids — a third party pushing into somebody else's claim.
if git log --format='%s%x09%(trailers:key=Unit,valueonly,separator=%x20)' \
       "origin/${BASE_BRANCH}..origin/${BRANCH}" 2>/dev/null \
   | awk -F'\t' '$1 == "Claim a PR-unit" || $1 ~ /^Claim [^ ]+$/ { found = 1 } END { exit !found }'; then
    refuse has_claim_commit
fi

# THREE CLASSES ARE ACCEPTED AND EVERY OTHER ONE IS REFUSED BY ITS OWN WORD. `NEEDS_CATCHUP`
# is the only thing the class decides below: `clean` skips the merge, the regeneration and the
# push because each of them has nothing to do, and skips NOTHING else — the gate, the delivery
# seam, the refusal words and the teardown are one code path for every class.
#
# `content` JOINED THEM ON 2026-09-02 (mission
# `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`), on `catch-up-claim.sh`'s own
# reasoning and in the same change. The class here is `claim-mergeability.sh`'s, a READER's
# PREDICTION computed with the repository's `.gitattributes` deliberately out of reach — so that
# it predicts GitHub, which applies no merge driver — while the merge below runs in a real
# checkout where `merge=union` on the generated indexes is in force. The reader is therefore
# pessimistic by construction against the writer, and every publication in that gap was refused
# `not_mechanical:content` without anyone ever attempting it.
#
# THE REFUSAL MOVED, IT DID NOT GO. A hunk the merge itself cannot settle still refuses
# `content_conflict` below, with nothing pushed and the branch byte-identical, and its author is
# still reached by `/moderate`'s `stranded-publication:<number>` question. What is gone is
# refusing on a guess. `unanswerable` keeps its refusal: it is the ABSENCE of a reading, and
# acting on an absence is what the three-valued class exists to prevent.
NEEDS_CATCHUP=true
case "$CLASS" in
    mechanical | content) ;;
    clean) NEEDS_CATCHUP=false ;;
    *) refuse "not_mechanical:${CLASS:-unreadable}" ;;
esac

# ── THE WORKTREE: attach to the published branch, never mint one ─────────────────────
# ATTACHED FOR BOTH CLASSES, DELIBERATELY. A `clean` publication needs no catch-up, but the
# GATE below is not part of the catch-up: `scan-branch-safety.sh` diffs a checkout of the
# branch against the base, so it needs one. The alternative — scanning without a worktree,
# against the remote refs — is cheaper per act and would give the gate a second way of being
# invoked; one worktree, attached and torn down by machinery that already exists, is the
# smaller change and keeps the gate's refusals byte-identical on both paths.
WORKTREE="${REPO_ROOT}/.worktrees/${WORKTREE_ID}"
if [ ! -d "$WORKTREE" ]; then
    [ -f "$MAKE_WORKTREE" ] || refuse no_worktree_script
    ( cd "$REPO_ROOT" && sh "$MAKE_WORKTREE" --branch "$BRANCH" "$WORKTREE_ID" ) >/dev/null 2>&1 \
        || refuse worktree_attach_failed
    [ -d "$WORKTREE" ] || refuse no_worktree
fi
on_branch=$(git -C "$WORKTREE" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '')
[ "$on_branch" = "$BRANCH" ] || refuse worktree_on_other_branch
[ -z "$(git -C "$WORKTREE" status --porcelain 2>/dev/null || printf 'x')" ] || refuse dirty_worktree

if [ "$NEEDS_CATCHUP" = true ]; then
    # ── THE MERGE, COMPOSED AND NEVER RE-DERIVED ─────────────────────────────────────
    [ -f "$CATCHUP" ] || refuse no_catchup_script
    catchup_out=$( ( cd "$WORKTREE" && sh "$CATCHUP" "$BASE_BRANCH" --resolve-mechanical ) 2>/dev/null || printf '')
    case "$catchup_out" in
        *'"already_current": true'*) report already_current "" ;;
        *'"caught_up": true'*) MERGED=true ;;
        *'"conflict_class": "content"'*) refuse content_conflict ;;
        *'"conflict_class": "mechanical"'*) refuse catchup_mechanical_unresolved ;;
        *'"reason": "merge_failed"'*) refuse catchup_merge_failed ;;
        *) refuse catchup_unreadable ;;
    esac

    # ── REGENERATE WITH THE REPOSITORY'S OWN TOOLING, NEVER BY HAND ──────────────────
    # This is the obligation `--resolve-mechanical` put on the caller, and it is the whole
    # repair: every generated path the merge resolved by taking a side is re-derived from the
    # MERGED source. Absent tooling is not a failure — a consuming repository has no
    # `outputs/` to build.
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

    # ── THE REPOSITORY'S OWN FAST CHECKS, BEFORE THE PUSH ────────────────────────────
    # A push that turns CI red costs a cycle and the reviewers' trust, and this one lands on a
    # branch behind an open pull request. Each check is named in its own refusal.
    if command -v node >/dev/null 2>&1; then
        for check in build-plugins/verify.mjs build-plugins/validate-metadata.mjs \
                     test-workflow-scripts.mjs; do
            [ -f "${WORKTREE}/scripts/${check}" ] || continue
            ( cd "$WORKTREE" && node "scripts/${check}" ) >/dev/null 2>&1 \
                || refuse "validation_failed:${check##*/}"
        done
    fi
    VALIDATED=true
fi

# ── THE GATE, READ BEFORE ANYTHING IS PUSHED OR MERGED ───────────────────────────────
# `secret` is never overridable and `leak` needs a human ruling; only `override_only` findings
# (the granularity nudge) let the delivery proceed. An unreadable gate is `scan_unreadable`,
# never `pass`.
if [ -f "$SCAN" ] && [ -f "$GATE" ]; then
    gate="$( ( cd "$WORKTREE" && sh "$SCAN" "origin/${BASE_BRANCH}" 2>/dev/null || printf '' ) \
             | sh "$GATE" 2>/dev/null || printf '')"
    [ -n "$gate" ] || refuse scan_unreadable
    case "$gate" in
        *'"decision": "pass"'*) ;;
        *'"override_only": true'*) ;;
        *'"overridable": false'*) refuse scan_held:hard ;;
        *'"decision": "block"'*) refuse scan_held:confirm ;;
        *) refuse scan_unreadable ;;
    esac
fi

# ── PUSH. Never a force, never an amend, never a rebase ──────────────────────────────
# Only the catch-up wrote anything to push. A `clean` settlement's branch is byte-identical to
# the published one, so there is no ref to move and `pushed` stays false.
if [ "$NEEDS_CATCHUP" = true ]; then
    git -C "$WORKTREE" push --quiet origin "HEAD:refs/heads/${BRANCH}" >/dev/null 2>&1 \
        || refuse push_failed
    PUSHED=true
fi

# ── DELIVER: one merge attempt, through the seam every other caller uses ─────────────
# The merge vocabulary is `merge-reason.sh`'s own and is never a second set; the method is
# read from `merge-method.sh` and never spelled here (`CLAUDE.md`, *Enforcement gates*).
# A delivery this environment could not attempt is `not_attempted` with its reason, never a
# refusal of the settlement: the branch IS caught up and pushed, and the next tick's retry
# finds it mergeable.
sh "${GATHER}/gh-rest.sh" available >/dev/null 2>&1 || report settled gh_unavailable
slug="$(sh "${GATHER}/gh-rest.sh" slug 2>/dev/null || printf '')"
[ -n "$slug" ] || report settled slug_unresolved

method="$(sh "${GATHER}/merge-method.sh" 2>/dev/null || printf 'squash')"
# THE SQUASH BODY IS READ, NEVER SPELLED (2026-09-03). `gather/scripts/merge-commit-body.sh`
# is the one derivation of `commit_title` / `commit_message`; without them the forge
# concatenates every commit on the branch into the trunk's record. A composer that could not
# read still yields a body (the story description when one was read, the fallback line otherwise), so the merge is never held on it.
body_json="$(sh "${GATHER}/merge-commit-body.sh" "${NUMBER}" 2>/dev/null || printf '')"
merge_title="$(printf '%s' "$body_json" | jq -r '.title // ""' 2>/dev/null || printf '')"
merge_body="$(printf '%s' "$body_json" | jq -r '.body // ""' 2>/dev/null || printf '')"
MERGE_BODY_SOURCE="$(printf '%s' "$body_json" | jq -r '.source // "unreadable:no_composer"' 2>/dev/null || printf 'unreadable:no_composer')"
set +e
merge_resp="$(sh "${GATHER}/gh-rest.sh" api "repos/${slug}/pulls/${NUMBER}/merge" \
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

report settled ""
