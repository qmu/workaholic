#!/bin/sh
# THE `too-large-commit` RULE: what it counts, and why.
#
# The decision recorded here is the mission's substance
# (make-the-per-commit-changed-lines-ceiling-a-rule-that-holds). It lives in the scan's
# lib/ rather than in a commit message because the rule had been overridden four times
# INSTEAD of being decided once, and an override is only meaningful against a stated rule.
#
# ---------------------------------------------------------------------------------
# THE PURPOSE, WHICH DECIDES EVERYTHING ELSE
#
# The ceiling exists to make commit count a comparable throughput unit -- a claim about
# IMPLEMENTATION commits -- and, downstream of that, to keep a commit reviewable. Those
# two goals agree on what should be counted: **new code a reviewer has to read**.
#
# ---------------------------------------------------------------------------------
# THE EVIDENCE (measured, not assumed)
#
# Five real instances, three from the originating feedback and two measured 2026-08-01.
# Non-`outputs/` totals under each candidate lever:
#
#   commit     shape            a+d   added   a+d minus     added minus
#                                             .workaholic/  .workaholic/
#   fa8033d3   spec batch       502     502        0             0      <- must pass
#   1179d916   implementation   772     765      707           702      <- must FIRE
#   044a3f8b   relocation       701     472      629           402      <- must pass
#
# Only the last column answers all three correctly. Each half is independently justified:
#
#   1. COUNT ADDED LINES ONLY. Deleted lines are not what a reviewer must understand, and
#      counting both makes a relocation cost double -- 260 lines moved is 520 charged
#      before any work is done. That penalises exactly the refactors worth encouraging.
#      A commit that only deletes now passes, which is the intended reading: removing code
#      is cheap to review and good for the codebase.
#
#   2. EXCLUDE `.workaholic/` ARTIFACT PROSE. Tickets, stories, missions and feedback are
#      specifications and records, not implementation, so they add no throughput to the
#      unit the rule is trying to standardise -- and their length is already governed by
#      their own norms (mission/scripts/size.sh, the story conventions). A four-ticket
#      batch breached the ceiling by construction: `create-ticket` caps a split at 2-4
#      tickets and a ticket at this repository's density runs 110-140 lines. Note this
#      exempts the artifact's PROSE only; code in the same commit still counts in full.
#
#   3. EXEMPT MERGE COMMITS (more than one parent). A merge authors nothing. Its changed
#      lines against the first parent are the whole of what it merges, and that content
#      was already measured on the commits being brought in, where the ceiling applies.
#      Without this, `/ship`'s own catch-up merge makes a ten-line branch inherit a block
#      for work it did not author -- and the busier the base, the likelier it fires.
#
# REJECTED, with reasons:
#
#   - Discount pure renames via `git -M`. Correct in principle and useless for the
#      instance that motivated it: 044a3f8b is a SPLIT, not a rename -- one file's content
#      distributed into two new ones -- and rename detection only matches whole files. It
#      is enabled anyway below, since it costs nothing and helps a true move, but it is
#      not the fix.
#   - Raise the ceiling. Moves the number without deciding what the number measures, which
#      is how the rule got here.
#   - Exempt spec commits by "no executable line". Requires classifying a commit's intent;
#      the `.workaholic/` path test asks the same question with a checkable answer.
#
# UNCHANGED: MAX_COMMIT_CHANGED_LINES stays 500, and the other `size` sub-rules
# (MAX_FILES, MAX_FILE_ADDED_LINES, MAX_FILE_BYTES) and the `secret`/`leak` tiers are not
# touched. The name `too-large-commit` and its `override` severity are unchanged.

# Is this path artifact prose rather than implementation? (Rule 2 above.)
commit_size_is_artifact_prose() {
    case "$1" in
        .workaholic/*) return 0 ;;
        *) return 1 ;;
    esac
}

# Does this commit have more than one parent? (Rule 3 above.)
commit_size_is_merge() {
    _csm=$(git rev-list --parents -n 1 "$1" 2>/dev/null | wc -w)
    [ "${_csm:-0}" -gt 2 ]
}
