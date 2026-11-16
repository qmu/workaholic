#!/bin/sh -eu
# The merge method every pull request this loop merges is merged with, derived in ONE place.
#
#   merge-method.sh          -> the word, on stdout (`merge`)
#
# WHY IT IS `merge` (2026-09-26, the developer's instruction, issue #1279 — superseding the
# 2026-09-01 squash ruling below). Asked why ~22 local `work-*` branches looked unfinished, the
# loop answered that they only LOOK unmerged because every pull request was squash-merged: a
# squash lands the unit's tree and leaves its branch tip off the base's ancestry, so
# `git branch --merged`, `survey-worktrees.sh`'s `merged` (`ahead == 0`) and every other
# ancestry reader answer "not merged" for a unit that landed. The developer's reply:
# 「だとしたらsquash mergeしないで欲しい」. So every merge is now a MERGE COMMIT, and a landed
# branch's tip is an ancestor of the base again — ancestry answers "did this land" with no
# network call and no tree comparison, and the hourly worktree sweep reclaims a landed unit.
#
# WHAT IT COSTS, STATED RATHER THAN HIDDEN: the branch-internal bookkeeping the squash kept off
# `main` — the claim stamp, legacy heartbeat commits, index refreshes, per-ticket commits —
# reaches `main` as SECOND-PARENT history. That is the accepted cost. The trunk stays readable
# as one line per landed unit through `git log --first-parent main`: each first-parent commit is
# the merge commit, and its title and body are `merge-commit-body.sh`'s composed ones (the pull
# request's title and the story's description), never the forge's `Merge pull request #N from …`.
#
# THE 2026-09-01 SQUASH RULING, KEPT AS HISTORY. It was measured on a consuming repository: one
# day of `main`, 275 commits, 59% of them carrying no product change, and the ruling chose a
# history of units over a history of the loop's memory. `--first-parent` now gives that same
# reading without collapsing the branch, so the ruling's aim survives its method.
#
# WHAT DID NOT MOVE FOR THE CLAIM PROTOCOL. `claims_superseded` asks the TREE (every one of the
# unit's tickets archived on the base) and `claims_branch_empty_against_base` the diff, so both
# still answer for branches already squash-landed; for a merge-committed branch the claim oracle
# (unmerged remote branches) simply stops listing it, and `delete_branch_on_merge`
# (`workaholify/scripts/check-repo-settings.sh`) still removes the remote branch at the merge.
# Branches squash-landed before this ruling stay non-ancestors; history is not rewritten.
#
# ONE DERIVATION, SEVEN CONSUMERS -- five REST call sites (`ship/scripts/merge-pr.sh`,
# `branching/scripts/publish-tree-pr.sh`, `drive/scripts/retry-undelivered.sh`,
# `drive/scripts/catch-up-claim.sh`, `branching/scripts/settle-stranded-publication.sh`) and two
# AGENT-level merges (the `review` route's inline merge in `workaholic:drive`, and the connector
# retry a `session_type_cannot_merge` refusal licenses, carried in `commands/implement.md`).
# A literal `merge_method=` at a call site is refused by `scripts/test-workflow-scripts.mjs`: seven
# copies of one word is exactly the drift this repository keeps single-sourcing to avoid, and a
# call site that merged the OTHER way would leave one route's branches reading unmerged, which is
# the hardest kind of inconsistency to notice.
#
# ITS SIBLING IS `merge-commit-body.sh` (2026-09-03), which answers the merge commit's
# `commit_title` and `commit_message` the same way. Every call site above reads both, so the
# first-parent line of `main` is the unit's own title rather than the forge's default.

set -eu
printf 'merge\n'
