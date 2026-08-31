#!/bin/sh -eu
# The branch the moderation tick's log lives on, derived in ONE place.
#
#   log-ref.sh        -> the branch name (`workaholic-log`)
#
# WHY THE LOG IS NOT ON `main` (2026-09-01, issue #782, the developer's instruction).
# **A commit is a change to the development target.** Measured on a consuming repository's
# `main`, one calendar day: 275 commits, of which 138 touched only `.workaholic/`, 25 were
# empty, 44 were merge commits and FIVE touched only the product. Squash-merging every pull
# request (`gather/scripts/merge-method.sh`) removed the merge commits and folded each unit's
# claim, heartbeat and story into that unit's one commit -- and left this log, which reaches
# the base as a DIRECT commit with no pull request at all, three times an hour, ~50 commits a
# day, as the single largest author of `main`'s history.
#
# Its CONTENT is load-bearing and was never in question: it is the tick's only memory across
# discarded containers (`log-read.sh`'s dedup sets, `question-state.sh`, `record-answer.sh`,
# `condition-age.sh`, `filed-records.sh`, `step-blocked-tick.sh`). What was wrong is its HOME.
# `CLAUDE.md` already said what it is -- *an operational log, not knowledge* -- and an
# operational log is not part of the product's history.
#
# SO IT MOVES TO ITS OWN BRANCH IN THIS SAME REPOSITORY. The repository stays the coordination
# medium and no server appears (the claim protocol's founding constraint); `main`'s log becomes
# a list of units of product change. The branch is an ORPHAN: it shares no history with `main`,
# carries nothing but `.workaholic/moderations/`, and can never be merged into `main` by
# accident.
#
# WHY NOT `refs/notes/*` OR A NAMESPACE OF OUR OWN: measured while designing the claim protocol
# (`drive/reference/claims.md`) -- this container's credential answers 403 on every namespace
# but `refs/heads/*`. A log the routine cannot push is not a log.
#
# THE NAME IS NOT `work-*` AND NOT `release/*`, deliberately: those are the two patterns
# `guard-git-branch.sh` and the claim scan key on, and a log branch matching either would be
# read as an in-flight claim or a release window. `workaholic-log` matches neither, and
# `claims_scan` only ever looks at `work-*`, so the claim protocol never sees this branch.
#
# `WORKAHOLIC_LOG_REF` overrides it -- a data source for a drill or a fixture, never a gate
# opt-out: `persist-log.sh` refuses a ref that names the repository's base branch, so there is
# no value of this variable that puts the log back on `main`.

set -eu
printf '%s\n' "${WORKAHOLIC_LOG_REF:-workaholic-log}"
