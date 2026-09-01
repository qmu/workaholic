#!/bin/sh
# THE ONE RULE FOR WHICH PUBLICATIONS ARE THE OPERATOR'S (2026-08-29, mission
# `follow-the-pull-requests-the-loop-opens-for-a-person`).
#
# Two scripts ask the same question about one publication and must never answer it
# differently:
#
#   branching/scripts/publish-tree-pr.sh          the SEAM. It refuses to auto-merge, and its
#                                                 refusal word is the answer.
#   moderate/scripts/list-operator-facing-pulls.sh  the READER. It asks the same question of a
#                                                 pull request that is already open, hours or
#                                                 days after the seam's own output is gone.
#
# The reader exists because the loop opens pull requests FOR A PERSON and then stops following
# them (measured 2026-08-29: #694 sat 18 hours unanswered). A second copy of the rule would let
# the two disagree, and the dangerous direction is specific: a reader that keyed on the
# `[Ruling] ` TITLE would lose exactly the pull request the operator retitled or opened by hand
# — which is precisely the one that is theirs.
#
# WHAT LIVES HERE IS THE TEST, NOT THE ACT. The seam's merge, its scan ladder and its output
# shape stay in `publish-tree-pr.sh`; the reader's REST paging and its own refusals stay in the
# reader. The reasoning behind each rule stays in `publish-tree-pr.sh`'s header, which is where
# a reader of either script is sent.
#
# IT IS FED A NORMALISED STREAM, WHICH IS WHAT LETS TWO DIFFERENT INPUTS SHARE ONE RULE. The
# seam has a git diff; the reader has `GET /repos/{}/pulls/{}/files`. Neither shape is the
# rule, so each caller ADAPTS its own input to one line per changed file:
#
#     <status><TAB><path><TAB><feedback_line_moved>
#
# `status` is git's letter (`A` `M` `D` `R` `C`), `path` the destination path, and the third
# field `1` when this file's own patch adds or removes a `feedback:` line and `0` otherwise.
# The adapter is trivial in both directions and is the ONLY thing either caller owns.
#
# THE TEST IS ON THE SHAPE OF THE CHANGE, NOT THE DIRECTORY (the seam's own words). A carried
# attribution and a brand-new mission both live under `.workaholic/missions/`, and every
# `/specificate` proposal writes one of the second kind — catching those would stop the loop's
# ordinary publications from merging at all. So a mission counts only when it ALREADY EXISTED
# on the base (`M`) and the diff moves its `feedback:` line, which is exactly and only what
# `carry-attribution.sh` writes. The mapping has no such ambiguity: nothing but a ruling writes
# `.claude/git-identities` here.
#
# STRATEGY OUTRANKS RULING, because the seam checks it first and this must be byte-identical to
# the seam. The two name different trees and ask for different operator acts — authoring a
# direction versus ruling on an attribution — and a publication that somehow did both is
# reported under the stronger of the two rather than under a third word nothing emits.
#
# Sourced, never executed.

# Read the normalised stream on stdin; print the refusal word, or nothing at all when the
# publication is an ordinary one the seam is free to merge. Never fails: an unparseable line
# contributes nothing, because a publication we could not classify must not become the
# operator's by accident.
publication_refusal_word() {
    awk -F '\t' '
        {
            status = $1
            path   = $2
            moved  = $3
            if (path == "") next
            if (path ~ /^\.workaholic\/strategies\//) { strategy = 1 }
            if (path == ".claude/git-identities") { ruling = 1 }
            if (status == "M" && path ~ /^\.workaholic\/missions\// && moved == "1") { ruling = 1 }
        }
        END {
            if (strategy) { print "strategy_touching"; exit }
            if (ruling)   { print "ruling_touching" }
        }
    '
}
