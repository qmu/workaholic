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
# WHY IT LIVES IN `gather` AND NOT IN `moderate`, and this was measured rather than chosen for
# tidiness. It started in `moderate/scripts/`, where the log's own steps are -- and
# `gather/scripts/migrate-moderations-off-main.sh` has to read it too, so the migration reached
# across into `moderate`. The build follows that edge: one call dragged **all 57 moderate
# scripts plus `standup` and `workaholify`** into the `catch`, `create-ticket`, `mission`, `ship`
# and `story` bundles, and CI's `Outputs Freshness` went red on 18 references those newly-copied
# scripts make to files no bundle carries. `gather` is the documented home of common operations
# (CLAUDE.md, *Design principles*) and is already in every bundle, which is the same argument
# that put `gh-rest.sh` here. A branch name is exactly that shape of fact: not the tick's, just
# read by it.
#
# `WORKAHOLIC_LOG_REF` overrides it -- a data source for a drill or a fixture, never a gate
# opt-out: `persist-log.sh` refuses a ref that names the repository's base branch, so there is
# no value of this variable that puts the log back on `main`.

# AND WHEN THERE IS NO BRANCH AT ALL (2026-09-03, the developer's instruction). Every word above
# rests on one premise: the tick runs in a container that is thrown away. Since 2026-09-02 the loop
# turns LOCALLY (`workaholic:loops`) in a session whose checkout persists between ticks, where
# `.workaholic/moderations/` is git-ignored and simply stays on disk — so the branch was carrying a
# copy of a file that never went anywhere, and this repository grew 126 commits on it that nobody
# read. `WORKAHOLIC_LOG_PERSIST=0` (declared in `.claude/settings.json`'s `env` block, the home
# `WORKAHOLIC_WIP_LIMIT` and `WORKAHOLIC_CADENCES` already use) turns the branch half of
# `persist-log.sh` and the whole of `hydrate-log.sh` off together, so the writer and the reader
# cannot disagree about whether a branch exists. **Absent means persist**: a repository on the
# Web-routine fallback is byte-identical to one before this existed, and the stated cost of
# declaring it there is that the tick loses its memory across containers and re-fires its
# questions. This name and this file do not move — the branch is still where the log goes for
# anyone who needs one.

set -eu
printf '%s\n' "${WORKAHOLIC_LOG_REF:-workaholic-log}"
