---
type: Feedback
title: Clear the residue the base already holds instead of stalling the loop forever
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-08T17:55:56+09:00
author: a@qmu.jp
supersedes: 
---

# Clear the residue the base already holds instead of stalling the loop forever

Source: https://github.com/qmu/workaholic/issues/1111

The unattended loop stalls forever on residue it can prove the base already holds. `sync-main.sh`
refusing `dirty_workspace` is correct by its own stated rationale — *a reset would discard a
developer's local commits* — but nothing above it clears residue that provably discards nothing, so
the coordinator reports the same freshen refusal every tick and `/implement` never reaches its
survey.

Measured 2026-09-08 on this repository: the main checkout sat 12 commits behind `origin/main` with 6
staged paths, and for 21 ticks over roughly 100 minutes the coordinator reported
`claimable_units_unreadable: not_current` with no `/implement` pass ever reaching `plan-units.sh`.
Of the 6 staged paths, 4 were blob-identical to `origin/main` (`git hash-object` matched
`git rev-parse origin/main:<path>`) and 2 were generated indexes `okf/scripts/refresh-index.sh`
rewrites, with `origin/main`'s copy the newer one. Untracked files: zero. The residue came from a
hand-run `git reset` (`reset: moving to HEAD^` in the reflog); no loop script produced it. Clearing
it by hand — reset, restore the generated indexes to HEAD, drop the four proved paths,
`git pull --ff-only` — made `claimable-units.sh` answer `{"claimable":2,"missions":2}` immediately.

This contradicts two of CLAUDE.md's own rules: *Only a concrete, VERIFIED external limitation may be
reported as a handoff*, and *routine engineering work must never be handed back to a person*.
Content the tree can prove is already on the base, and a generated file the repository's own
generator rewrites, are neither an external limitation nor a judgement a person must make. The proof
form wanted already exists in shape — `superseded`'s: a reading the tree established that cannot
become false when re-derived — so no new class of judgement is needed.

The ask is explicit that `sync-main.sh` must **not** be loosened: the property it protects is
correct. What is wanted is a layer above it that clears **only** provable residue and then lets the
existing freshen run.

Alongside it, an adjacent defect found in the same tick: `workaholic:notify`'s precondition-stop
class is a closed named list whose only current member is `no_plugin_source`, so a run that
terminates before the survey for any other reason posts nothing at all. A person happened to be at
the terminal this time; an unattended routine would have been silent for the whole 100 minutes.
Whether a stop is visible should not depend on that list being exhaustive.
