#!/bin/sh
# unmerged-branches.sh — THE ONE WALK over what an unmerged remote branch ADDS.
#
# Sourced, never executed, from a specificate script with SCRIPT_DIR its own scripts/ dir:
#   . "$SCRIPT_DIR/lib/unmerged-branches.sh"      (the reader sets UNMERGED_BRANCHES_LABEL first)
#
#   unmerged_branches_base                          prints the base ref, or nothing
#   unmerged_branches_warn_shallow                  one stderr line when the clone is shallow
#   unmerged_branches_added_paths BASE PATHSPEC...  prints "<ref><TAB><path>" per added/modified
#                                                   path under PATHSPEC on every unmerged branch
#
# Both callers set UNMERGED_BRANCHES_LABEL to their own script name so a warning names
# the reader a reader is looking at.
#
# ═══ WHY IT EXISTS (2026-09-01, ticket 20260901042313) ═══════════════════════════════
# `list-proposed-refs.sh` owned this walk to answer *has this ask been proposed*, reading
# the missions and tickets a branch adds. `list-inbound-issues.sh` needed the same walk
# for a different artifact — the feedback records a branch adds — because its
# `already_captured` exclusion grepped the caller's checkout, which at the propose seam is
# a checkout of the base: an open issue whose record exists only on an unmerged proposal
# branch was offered to `[Specificate]` again every hour. Measured 2026-09-01: issue #812's
# record sat on `work-20260901-022335` behind pull request #813 since 02:23 and #812 was
# re-offered at 03:28 and again at 04:21, each re-take writing a duplicate record and
# opening a fresh pull request that conflicted with every other open proposal.
#
# THE WALK IS EXTRACTED RATHER THAN COPIED. Two walkers over one oracle is the failure
# `read-feedback-relation.sh`'s header names for the relation, one artifact over: they
# drift, and the side that under-reads is the side that duplicates. Only the PATHSPEC and
# the caller's own path filter differ, so only those are arguments.
#
# ═══ GIT-NATIVE, NOT `gh pr list` ════════════════════════════════════════════════════
# An unmerged remote branch is the same oracle the claim protocol rests on
# (drive/scripts/lib/claims.sh): no auth, no API budget, no network beyond the fetch the
# caller already did. It over-reads by exactly the branches that are pushed with no pull
# request, which is the safe direction for both callers — see below.
#
# ═══ WHICH DIRECTION TO ERR: OVER-READ ═══════════════════════════════════════════════
# Every ambiguous case here resolves toward INCLUDING the branch. For
# `list-proposed-refs.sh` that suppresses a proposal; for `list-inbound-issues.sh` it
# excludes an issue. Both are the quiet failure; the loud, measured one is the duplicate.
# A shallow clone cannot reduce `rev-list --count base..ref` across a graft and so counts
# long-merged branches as ahead: the merge base is tested first, and a branch whose
# ancestry is unanswerable is included rather than dropped. The degradation goes to
# STDERR — stdout stays exactly the machine-readable lines, so a warning can never be
# mistaken for one.
#
# ═══ COST, MEASURED (2026-08-05) ═════════════════════════════════════════════════════
# One ancestry test per remote branch plus one tree diff per unmerged branch: ~4s over 195
# remote branches, of which 194 were merged-but-undeleted. The dominant term is the branch
# COUNT, not the artifact count, so deleting merged branches is what keeps this cheap
# (`delete_branch_on_merge`, which `/workaholify` converges). If it ever stops being cheap,
# the fix is `for-each-ref --no-merged` — one process instead of N — not a second pass.
#
# ═══ CLOSING A PULL REQUEST WITHOUT MERGING ══════════════════════════════════════════
# The BRANCH is what this keys on, so a closed-but-undeleted branch still counts. Deleting
# the branch is the act that frees its artifacts — the same invariant the claim protocol
# uses, where deleting the branch is what releases a claim.

UNMERGED_BRANCHES_LABEL="${UNMERGED_BRANCHES_LABEL:-unmerged-branches}"

unmerged_branches_base() {
    for cand in origin/main origin/master main master; do
        if git rev-parse --verify --quiet "${cand}^{commit}" >/dev/null 2>&1; then
            printf '%s\n' "$cand"
            return 0
        fi
    done
    return 0
}

unmerged_branches_warn_shallow() {
    if [ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo false)" = "true" ]; then
        echo "${UNMERGED_BRANCHES_LABEL}: shallow clone; merged branches may be read as open (over-reading)" >&2
    fi
    return 0
}

# unmerged_branches_added_paths BASE PATHSPEC...
#
# ONLY WHAT THE BRANCH ADDS. A two-dot tree diff, not `ls-tree`: a branch carries the WHOLE
# artifact tree, and materialising every archived artifact on every unmerged branch is
# thousands of `git show` calls — measured at over two minutes in this repository, on a path
# a reporter is waiting on. Anything a branch shares with the base is already covered by the
# caller's own working-tree walk, so the difference is exactly the new artifacts. Two-dot on
# purpose: it compares trees and needs no merge base, so it still answers in a clone too
# shallow for `...` to resolve.
unmerged_branches_added_paths() {
    _ub_base="$1"
    shift
    [ -n "$_ub_base" ] || return 0
    [ "$#" -gt 0 ] || return 0

    _ub_tab="$(printf '\t')"
    for _ub_ref in $(git for-each-ref --format='%(refname)' refs/remotes/origin 2>/dev/null || true); do
        _ub_short=${_ub_ref#refs/remotes/}
        [ "$_ub_short" = "origin/HEAD" ] && continue
        [ "$_ub_short" = "$_ub_base" ] && continue
        # Unanswerable ancestry (a shallow graft) counts as unmerged: over-read.
        if [ -n "$(git merge-base "$_ub_base" "$_ub_ref" 2>/dev/null || true)" ]; then
            [ "$(git rev-list --count "${_ub_base}..${_ub_ref}" 2>/dev/null || echo 0)" -gt 0 ] || continue
        fi
        for _ub_path in $(git diff --name-only --diff-filter=AM "$_ub_base" "$_ub_ref" -- "$@" 2>/dev/null || true); do
            printf '%s%s%s\n' "$_ub_ref" "$_ub_tab" "$_ub_path"
        done
    done
    return 0
}
