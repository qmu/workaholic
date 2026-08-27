---
type: Feedback
title: Read whether the base survived what the loop merged
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-27T16:16:40+00:00
author: a@qmu.jp
supersedes: 
---

# Read whether the base survived what the loop merged

The [Propose] routine asks for a reading of whether the base survived what the loop merged, and one place that says so out loud.

Source: https://github.com/qmu/workaholic/issues/661

Nothing in this plugin reads a check run. No script under `skills/*/scripts/` issues a
check-runs request, a workflow-run read or a required-status read; the single approximation is
`moderate/scripts/pulls-state.sh`, which infers `blocked_by: checks` from one pull request's
`mergeable_state == unstable` and is consulted only by the two reporting steps, never by a merge
seam. `ship/scripts/merge-pr.sh` PUTs the merge and reports where the commit landed; it asks
nothing about whether the commit is good. So the loop merges its own work, lands it on `main`,
and never learns what the base's checks then said.

What must become true:

- One reader answers, for a given commit, whether the base's checks are `green`, `red` or
  `unanswerable` — the three-valued shape `claim-merged.sh` already establishes, because a read
  that could not be made must never be dressed as a green one. It goes through
  `gather/scripts/gh-rest.sh` like every other GitHub read, and it degrades by name offline.
- A red base is attributed: the first commit the reader can call red, walking back over the
  base's own history to the last commit it can call green, and the pull request that landed it.
  A walk that cannot reach a green commit answers `unattributable` rather than blaming the tip.
- A red base reaches a person exactly once per commit — a `/moderate` step whose question is
  addressed to the author of the attributed merge, keyed so an hourly tick asks once and no more.
- A driving run names the reading in its run report, beside the per-unit outcomes it already
  carries.
- The reading gates nothing. The merge is untouched, `/ship` is untouched, quality stays gated
  at the `release/*` QA window exactly as this repository decided, and `/implement` keeps driving.
  What changes is only that the loop holds the fact and says it.

Why it commits to the strategy: the Aim is that the development loop runs itself. Eleven missions
have landed against it, every one about the loop's bookkeeping of its own units — which claim is
live, which is superseded, which was undelivered, which direction is dormant or arrived. The loop
knows a great deal about the state of its work and nothing about whether that work held. A green
base and a base nobody has looked at are, to this loop, the same reading.

Chosen against letting the loop judge whether the direction has arrived (that question already
reaches a person hourly, keyed `direction-arrived:`, and deciding a direction is finished is the
operator's act by design). Rejected inside the mission's own scope: blocking the merge on a red
check, which contradicts the standing decision that `main` is the continuously auto-merged
development branch and quality is gated at the `release/*` QA window. Read and say; never gate.

The ask names its own mission plan: title, experience, and an ordered set of eight tickets.
