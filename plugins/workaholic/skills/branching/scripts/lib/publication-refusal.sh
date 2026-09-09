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
# `status` is git's letter (`A` `M` `D` `R` `C`, optionally score-suffixed as git writes
# `R100`), `path` the destination path, and the third field `1` when this file's own patch adds
# or removes a `feedback:` line and `0` otherwise. The adapter is trivial in both directions and
# is the ONLY thing either caller owns.
#
# THE TEST IS ON THE SHAPE OF THE CHANGE, NOT THE DIRECTORY (the seam's own words). A carried
# attribution and a brand-new mission both live under `.workaholic/missions/`, and every
# `/specificate` proposal writes one of the second kind — catching those would stop the loop's
# ordinary publications from merging at all. So a mission counts only when it ALREADY EXISTED
# on the base (`M`) and the diff moves its `feedback:` line. The mapping has no such ambiguity:
# nothing but a ruling writes `.claude/git-identities` here.
#
# ═══ THE MISSION ARM ALSO ASKS WHAT ELSE THE PUBLICATION CARRIED ═════════════════════
# (2026-09-08, mission `let-the-loop-grow-a-mission-without-handing-it-back-to-a-person`.)
#
# `M` on an existing mission with the `feedback:` line moved is NOT exactly and only what
# `carry-attribution.sh` writes, which is what this header used to claim. TWO acts move that
# line and their per-line diffs are identical:
#
#   the RULING          `carry-attribution.sh` appends a named strategy's existing refs to one
#                       mission. Read its header: it stages THE ONE PATH, never commits, and
#                       deliberately does not refresh the OKF indexes. A ruling therefore ADDS
#                       NO FILE ANYWHERE — it cannot: the script has no other write.
#   the EXTENSION       `/specificate` appending a feedback ref while it grows an existing
#                       mission. It always ADDS at least the feedback record it just wrote, and
#                       usually the ticket files beside it.
#
# So the distinguishing term is derived from what each act WRITES rather than guessed: a
# publication whose mission modification is accompanied by an ADDED artifact is an extension,
# and an extension is ordinary routine work.
#
#   A ruling touches:      `.workaholic/missions/<area>/<slug>/mission.md`  (M)
#                          and, when a caller regenerates them, the OKF indexes:
#                          `.workaholic/index.md` and `.workaholic/<area>/index.md` (M or A).
#   A ruling cannot touch: any added ticket, any added feedback record, any added mission, any
#                          added or renamed file at all outside those generated indexes.
#
# MEASURED 2026-09-08: PR #1097 and #1094 each added a single `feedback:` ref to the existing
# mission `make-slack-intake-incremental-across-messages-threads-and-mentions` and were held
# `ruling_touching` for five hours while `main` moved under them and conflicted; #1094's target
# mission was archived `achieved` while it waited, so it had nowhere to land and was closed as a
# duplicate. PR #1112, MINTING a new mission in the same window, landed in four minutes. The
# incentive was inverted: fragmenting the work flowed, growing a mission halted.
#
# THE GENERATED-INDEX EXEMPTION IS STATED BY PATH, NEVER INFERRED. `okf/scripts/refresh-index.sh`
# writes `.workaholic/index.md` and one `.workaholic/<area>/index.md` per flat area and nothing
# else, so the set is exactly those two shapes — one path segment deep. Inferring it from
# "looks generated" would let an added artifact one directory over buy an extension the
# operator's word.
#
# ═══ WHAT THIS DELIBERATELY DOES NOT NARROW, AND WHAT THAT COSTS ═════════════════════
# The ask is explicit that the rule's AIM need not be loosened, so only the one measured
# collision moves and every ambiguity still errs toward the operator:
#
#   * `.claude/git-identities` stays UNCONDITIONAL. A publication carrying that file plus any
#     amount of other work is still the operator's, because nothing but a ruling writes it.
#   * `strategy_touching` still OUTRANKS, unchanged and checked first, because this must be
#     byte-identical to the seam.
#   * Only an ADDED artifact disqualifies the mission arm. A publication carrying the mission
#     modification alongside a MODIFIED or DELETED file elsewhere stays `ruling_touching`: an
#     extension is recognised by what it writes, and a ruling accompanied by an unrelated edit
#     is a shape no caller in this repository produces, so the safe direction is the operator's.
#   * An unparseable line still contributes NOTHING, because a publication we could not classify
#     must not become the operator's by accident.
#
# THE COST, STATED: a hand-made publication that carries a genuine attribution ruling AND adds
# an unrelated file now auto-merges under `WORKAHOLIC_AUTO_MERGE=1`. `/specificate`'s
# announcement route is `carry-attribution.sh`'s one caller and it stages that single path, so
# this repository emits no such publication; a person who wants one is the person who can also
# leave the variable unset.
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
            if (status == "M" && path ~ /^\.workaholic\/missions\// && moved == "1") { mission_ruling = 1 }
            # An added artifact is what a ruling cannot write and an extension always does.
            # The generated OKF indexes are exempt by path: `.workaholic/index.md` and one
            # `.workaholic/<area>/index.md`, which is the whole of what refresh-index.sh emits.
            if (status ~ /^[ACR]/ \
                && path != ".workaholic/index.md" \
                && path !~ /^\.workaholic\/[^\/]+\/index\.md$/) { added_artifact = 1 }
        }
        END {
            if (strategy) { print "strategy_touching"; exit }
            if (ruling) { print "ruling_touching"; exit }
            if (mission_ruling && !added_artifact) { print "ruling_touching" }
        }
    '
}
