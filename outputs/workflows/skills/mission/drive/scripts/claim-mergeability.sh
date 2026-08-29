#!/bin/sh -eu
# Does this claim branch still merge into the base, and if not, who has to decide?
#
# Usage: claim-mergeability.sh <branch> [base-ref]
# Output: one JSON line, always exit 0
#   {"readable": true, "branch": "...", "base": "origin/main", "class": "clean",
#    "reason": "", "already_current": false,
#    "conflicted_files": [...], "append_only_files": [...], "mechanical_files": [...],
#    "content_files": [...]}
#   {"readable": false, ..., "class": "unanswerable", "reason": "no_merge_base"}
#
# WHY IT EXISTS (2026-08-29, mission `land-the-loop-s-own-work-when-the-base-moves-under-it`).
# Nothing in the loop looked at a claim branch's mergeability after its pull request opened, so
# a unit finished and refused its merge was stranded the moment the base moved: `/moderate`'s
# `merge-conflicts` step reports a conflicted PULL REQUEST and says in its own header that it
# never rebases, and `retry-undelivered.sh` re-attempts the MERGE, which a moved base refuses
# again every hour. Measured 2026-08-29: pull requests #622, #625, #633 and #688 conflicting
# with `main`, three of them recorded `report_undelivered` two days earlier, with 4 active
# missions and 10 queued tickets behind them.
#
# FOUR VALUES, AND `unanswerable` NEVER COLLAPSES INTO `content`:
#   clean         the merge would apply with no conflict at all
#   mechanical    every remaining conflict is a version/lockstep manifest or generated output,
#                 or an append-only `.workaholic/` file the writer resolves by shape
#   content       some other path conflicts — a person must judge which side keeps its behaviour
#   unanswerable  the question could not be asked here (no merge base, truncated history, a ref
#                 this clone cannot read, a git without `merge-tree --write-tree`)
# The fourth is its own value on the merged-lookup precedent (`lib/claims.sh`,
# `claims_merged_state`): a wrong `clean` pushes a merge nobody proved, while a wrong `content`
# only delays a unit — so a reading we could not make is never promoted to one we could.
#
# THE CLASSIFICATION IS NOT THIS SCRIPT'S. `ship/scripts/catchup-main.sh` is the writer that
# performs the merge, and the one real risk here is a second classifier that can disagree with
# it. Both read `ship/scripts/lib/conflict-class.sh` — the scope test, the append-only shape
# proof and the mechanical allowlist — and neither restates the other's rule. The dangerous
# direction is specific and is the reason the shape test is shared rather than approximated:
# the writer RESOLVES an append-only `.workaholic/` conflict, so a reader that called those
# `content` would report *a human must decide* for every pair of units that each appended a
# `## Changelog` line, which is nearly every concurrent pair this repository produces.
#
# IT MAKES NO NETWORK CALL AND WRITES NOTHING. `lib/claims.sh`'s `claims_fetch` deepens a
# shallow clone before anything reads ancestry, so by the time the claim oracle renders a row
# the refs are present and this is offline by construction. `git merge-tree --write-tree`
# computes the merge into the object store without touching a worktree, an index or a ref —
# the same property that lets the claim reader stay a pure read.
#
# IT IS REPORTED, NEVER ACTED ON HERE. All four values are JUDGEMENTS (`../reference/claims.md`,
# *Proofs and judgements*): a base that moves is exactly a reading that becomes false by looking
# again, which is the one property a proof must not have. `catch-up-claim.sh` re-derives it at
# the moment of its own act rather than trusting a list it was handed.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/../../ship/scripts//lib/conflict-class.sh"

BRANCH="${1:-}"
BASE="${2:-}"

if [ -z "$BRANCH" ]; then
    echo 'Usage: claim-mergeability.sh <branch> [base-ref]' >&2
    exit 1
fi

json_str() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/[[:cntrl:]]/ /g'
}

CONFLICTED=""
APPEND_ONLY=""
MECHANICAL=""
CONTENT=""
ALREADY_CURRENT=false

# A newline-separated list rendered as a JSON array body.
json_list() {
    printf '%s\n' "${1:-}" | awk 'NF { printf "%s\"%s\"", sep, $0; sep = ", " }'
}

emit() {
    printf '{"readable": %s, "branch": "%s", "base": "%s", "class": "%s", "reason": "%s", "already_current": %s, "conflicted_files": [%s], "append_only_files": [%s], "mechanical_files": [%s], "content_files": [%s]}\n' \
        "$1" "$(json_str "$BRANCH")" "$(json_str "$BASE")" "$2" "$(json_str "${3:-}")" \
        "$ALREADY_CURRENT" \
        "$(json_list "$CONFLICTED")" "$(json_list "$APPEND_ONLY")" \
        "$(json_list "$MECHANICAL")" "$(json_list "$CONTENT")"
    exit 0
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || emit false unanswerable not_a_repository

# The base the "unmerged" set is measured against, resolved exactly as the claim oracle does.
if [ -z "$BASE" ]; then
    for _cm_b in origin/main origin/master main master; do
        if git rev-parse --verify --quiet "${_cm_b}^{commit}" >/dev/null 2>&1; then
            BASE="$_cm_b"
            break
        fi
    done
fi
[ -n "$BASE" ] || emit false unanswerable no_base

# The branch is named short (`work-…`); a caller may also hand in a full ref. Neither is
# guessed at: an unresolvable name is `unanswerable`, never `content`.
BRANCH_REF="$BRANCH"
git rev-parse --verify --quiet "${BRANCH_REF}^{commit}" >/dev/null 2>&1 \
    || BRANCH_REF="origin/${BRANCH}"
git rev-parse --verify --quiet "${BRANCH_REF}^{commit}" >/dev/null 2>&1 \
    || emit false unanswerable unreadable_ref
git rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null 2>&1 \
    || emit false unanswerable unreadable_base

# TRUNCATED HISTORY IS THE ONE CASE THE QUESTION IS GENUINELY UNASKABLE. Across a graft
# boundary the merge base is invisible, and a merge computed without one is a merge of two
# unrelated trees — every path conflicts and the answer would be a confident lie.
[ -n "$(git merge-base "$BASE" "$BRANCH_REF" 2>/dev/null || true)" ] \
    || emit false unanswerable no_merge_base

# Already current: the base tip is an ancestor of the branch, so a catch-up would move nothing.
# Reported rather than folded into `clean` — *would merge* and *has nothing to merge* are
# different facts, and only the second means a writer must touch no ref.
if git merge-base --is-ancestor "$BASE" "$BRANCH_REF" 2>/dev/null; then
    ALREADY_CURRENT=true
fi

TMP=$(mktemp -d 2>/dev/null || printf '')
[ -n "$TMP" ] || emit false unanswerable no_tmpdir
trap 'rm -rf "$TMP"' EXIT INT TERM

# OURS IS THE CLAIM BRANCH, THEIRS IS THE BASE — the same orientation `catchup-main.sh` merges
# in (`git merge origin/<base>` from the branch), so the stages this reads are the stages that
# writer would resolve. The shape test is symmetric, but an asymmetric one added later would
# silently invert if the orientation were left to chance.
set +e
git merge-tree --write-tree "$BRANCH_REF" "$BASE" >"${TMP}/out" 2>"${TMP}/err"
MT_STATUS=$?
set -e

case "$MT_STATUS" in
    0) emit true clean "" ;;
    1) ;;
    *)
        # A git too old for `--write-tree` (the option arrived in 2.38) and a genuine failure
        # both land here, and both are `unanswerable` rather than a guess.
        if grep -qi 'unknown option\|usage:' "${TMP}/err" 2>/dev/null; then
            emit false unanswerable merge_tree_unsupported
        fi
        emit false unanswerable merge_tree_failed
        ;;
esac

# Conflicted file info: `<mode> <object> <stage>\t<path>`, one line per stage, until the blank
# line that opens the informational-message section.
awk 'NR == 1 { next } /^$/ { exit } { print }' "${TMP}/out" >"${TMP}/stages"

CONFLICTED=$(awk -F'\t' 'NF > 1 { print $2 }' "${TMP}/stages" | sort -u)
[ -n "$CONFLICTED" ] || emit false unanswerable no_conflicted_paths

CLASS="mechanical"
NL='
'
# Line-based, never word-based: a path is whatever the line holds, so nothing here depends on
# a path carrying no spaces. The loop reads from a FILE rather than a pipe so the three lists
# it builds survive it (a pipeline's last stage is a subshell).
printf '%s\n' "$CONFLICTED" >"${TMP}/paths"
while IFS= read -r _cm_p; do
    [ -n "$_cm_p" ] || continue
    # The three stages of this path, materialised from the object store. A missing stage is
    # an add/add or a delete/modify, which the shared shape test refuses by construction.
    for _cm_s in 1 2 3; do
        _cm_oid=$(awk -F'\t' -v p="$_cm_p" -v s="$_cm_s" \
            '$2 == p { split($1, f, " "); if (f[3] == s) { print f[2]; exit } }' "${TMP}/stages")
        rm -f "${TMP}/stage${_cm_s}"
        if [ -n "$_cm_oid" ]; then
            git cat-file blob "$_cm_oid" >"${TMP}/stage${_cm_s}" 2>/dev/null || \
                rm -f "${TMP}/stage${_cm_s}"
        fi
    done

    if conflict_class_append_only "$_cm_p" "${TMP}/stage1" "${TMP}/stage2" "${TMP}/stage3"; then
        APPEND_ONLY="${APPEND_ONLY}${APPEND_ONLY:+${NL}}${_cm_p}"
        continue
    fi
    if conflict_class_mechanical "$_cm_p" "${TMP}/stage1" "${TMP}/stage2" "${TMP}/stage3"; then
        MECHANICAL="${MECHANICAL}${MECHANICAL:+${NL}}${_cm_p}"
        continue
    fi
    CONTENT="${CONTENT}${CONTENT:+${NL}}${_cm_p}"
    CLASS="content"
done <"${TMP}/paths"

emit true "$CLASS" ""
