#!/bin/sh -eu
# The merge method every pull request this loop merges is merged with, derived in ONE place.
#
#   merge-method.sh          -> the word, on stdout (`squash`)
#
# WHY IT IS `squash` (2026-09-01, the developer's instruction). Measured on a consuming
# repository the day the ruling was made — `main`, one calendar day, 275 commits:
#
#   138  touch only `.workaholic/`      (the loop's own bookkeeping)
#    63  mixed
#    44  merge commits
#    25  empty                          (`Refresh heartbeat`, `Resume a PR-unit`)
#     5  touch only the product
#
# **A commit is a change to the development target.** That is the principle, and a history in
# which 59% of the commits carry no product change at all does not express it — a person
# reading `git log` to find out what the product did has to read past the loop's own memory to
# find it. Most of that noise is BRANCH-INTERNAL and correct where it lives: the claim commit
# IS the claim (`drive/reference/claims.md`), the heartbeat IS the branch tip, and a unit's
# story and its mission hours are artifacts the unit produced. None of them is a fact about
# `main`. A merge commit carries every one of them onto `main` verbatim; a squash carries the
# unit's TREE and one subject.
#
# WHAT IT COSTS, STATED RATHER THAN HIDDEN: a unit's per-ticket commits collapse into one, so
# `main` no longer shows ticket-level granularity inside a unit. That granularity is not lost —
# it is on the pull request, which is never deleted, in the unit's branch story, and in the
# ticket archive under `archive/<branch>/`. What `main` gains is that its own log is a list of
# units of product change, which is what a person opens it for.
#
# WHY IT IS SAFE FOR THE CLAIM PROTOCOL, and this is the part that had to be checked rather
# than assumed. A squash-merged branch is NOT an ancestor of the base, so
# `git rev-list --count base..ref` stays positive and the branch keeps appearing in the scan —
# which would be fatal if `superseded` were derived from ancestry. It is not: `claims_superseded`
# asks the TREE (every one of the unit's tickets archived on the base, matched by filename under
# any branch directory) and a squash preserves the tree exactly. So a squash-merged claim reads
# `superseded`, which is the correct verdict, and `retire-claim.sh` retires it as it always did.
#
# It is nonetheless COUPLED to `delete_branch_on_merge`, which is why the two shipped together:
# with the setting off, a squash-merged branch survives as a `superseded` row forever instead of
# disappearing at the merge. `workaholify/scripts/check-repo-settings.sh` is where that setting
# is applied, and its header carries the other half of this reasoning.
#
# ONE DERIVATION, SEVEN CONSUMERS -- five REST call sites (`ship/scripts/merge-pr.sh`,
# `branching/scripts/publish-tree-pr.sh`, `drive/scripts/retry-undelivered.sh`,
# `drive/scripts/catch-up-claim.sh`, `branching/scripts/settle-stranded-publication.sh`) and two
# AGENT-level merges (the `review` route's inline merge in `workaholic:drive`, and the connector
# retry a `session_type_cannot_merge` refusal licenses, carried in `commands/implement.md`).
# A literal `merge_method=` at a call site is refused by `scripts/test-workflow-scripts.mjs`: seven
# copies of one word is exactly the drift this repository keeps single-sourcing to avoid, and a
# call site that merges the OTHER way would put the noise back on `main` for one route only,
# which is the hardest kind of inconsistency to notice.
#
# ITS SIBLING IS `merge-commit-body.sh` (2026-09-03), which answers the squash `commit_title` and
# `commit_message` the same way and for the same reason. The method alone was half the record: a
# squash whose call carries no body gets the forge's concatenation of every commit on the branch,
# so the bookkeeping this method exists to keep off `main` landed there inside the squash body --
# measured, 48 such commits on `main`, the longest 11,515 lines. Every call site above reads both.

set -eu
printf 'squash\n'
