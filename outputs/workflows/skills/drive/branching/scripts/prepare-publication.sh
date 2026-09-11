#!/bin/sh -eu
# Prepare one publication branch; never merge or close its pull request.
# Usage: prepare-publication.sh PR [BASE] [--catchup-only]
# Ordinary settlement and operator-facing catch-up share preparation, not delivery.
# The operator mode re-proves ownership and absence of reviews, including before push.
# The reader selects the publication; actual merge conflicts decide whether it can be
# caught up. Regenerate derived files and validate before a non-forced branch push.
# Dirty work and meaningful unresolved conflicts are retained, never discarded.
# Output: settled|already_current|settle_refused, reason, class, worktree_path,
# merged (local catch-up only), regenerated, validated, pushed and delivery.
# delivery is not_attempted, or "not_attempted: operator_facing" in operator mode.
# Only settle-stranded-publication.sh can proceed from ordinary preparation to delivery.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/base-ref-gate.sh"
READER="${SCRIPT_DIR}/list-stranded-publications.sh"
GATHER="${SCRIPT_DIR}/../../gather/scripts"
CATCHUP="${SCRIPT_DIR}/../../ship/scripts/catchup-main.sh"
MAKE_WORKTREE="${SCRIPT_DIR}/create-mission-worktree.sh"
CLEAN_WORKTREE="${SCRIPT_DIR}/cleanup-mission-worktree.sh"
MERGE_REASON="${SCRIPT_DIR}/merge-reason.sh"
SCAN="${SCRIPT_DIR}/../../release-scan/scripts/scan-branch-safety.sh"
GATE="${SCRIPT_DIR}/../../release-scan/scripts/gate-decision.sh"

NUMBER="${1:-}"
BASE_BRANCH="${2:-main}"
CATCHUP_ONLY=false
case "${3:-}" in '') ;; --catchup-only) CATCHUP_ONLY=true; READER="$SCRIPT_DIR/list-operator-facing-pulls.sh";; *) exit 2;; esac
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
[ "$CATCHUP_ONLY" = false ] || DELIVERY="not_attempted: operator_facing"
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

row="$(printf '%s' "$rows" | jq -c --arg n "$NUMBER" '(.publications // .pulls // [])[] | select((.number|tostring) == $n)' 2>/dev/null || printf '')"
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

if [ "$CATCHUP_ONLY" = true ]; then
    # Refresh an unreviewed publication, never exercise the operator's ruling.
    slug=$(sh "$GATHER/gh-rest.sh" slug 2>/dev/null || true)
    actor=$(sh "$GATHER/gh-rest.sh" api user --jq .login 2>/dev/null || true)
    [ -n "$actor" ] && [ "$actor" = "$(printf '%s' "$row" | jq -r .author)" ] || refuse publication_not_owned
    reviews=$(sh "$GATHER/gh-rest.sh" api "repos/$slug/pulls/$NUMBER/reviews?per_page=100" 2>/dev/null || printf 'null')
    printf '%s' "$reviews" | jq -e 'type=="array" and length==0' >/dev/null 2>&1 || refuse reviewed_or_reviews_unreadable
    [ "$(printf '%s' "$row" | jq -r '.already_current // false')" != true ] || report already_current ""
fi

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
# A conflict-free merge is not proof the base is already included. Operator catch-up
# keeps even a clean-but-behind branch current without taking its delivery decision.
[ "$CATCHUP_ONLY" = false ] || NEEDS_CATCHUP=true

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
    REFRESH_INDEX="${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh"
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
    if [ "$CATCHUP_ONLY" = true ]; then
        # Validation can take minutes. Do not update a branch that gained a review meanwhile.
        reviews=$(sh "$GATHER/gh-rest.sh" api "repos/$slug/pulls/$NUMBER/reviews?per_page=100" 2>/dev/null || printf 'null')
        printf '%s' "$reviews" | jq -e 'type=="array" and length==0' >/dev/null 2>&1 || refuse reviewed_or_reviews_unreadable
    fi
    { base_ref_gate push "HEAD:refs/heads/${BRANCH}" && git -C "$WORKTREE" push --quiet origin "HEAD:refs/heads/${BRANCH}" >/dev/null 2>&1; } \
        || refuse push_failed
    PUSHED=true
fi

# This mode has no edge into PR merge or closure. The original ruling stays pending.
if [ "$CATCHUP_ONLY" = true ]; then
    DELIVERY="not_attempted: operator_facing"
    report settled ""
fi

report settled ""
