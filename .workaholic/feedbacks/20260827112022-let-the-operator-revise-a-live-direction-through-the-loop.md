---
type: Feedback
title: Let the operator revise a live direction through the loop
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-27T11:20:22+00:00
author: a@qmu.jp
supersedes: 
---

# Let the operator revise a live direction through the loop

Source: https://github.com/qmu/workaholic/issues/655

The `[Propose]` routine opened this ask against the strategy
`an-autonomous-improvement-loop-run-by-the-routines` (move: breadth).

## What it asks for

Give a **live** strategy a third writer, so the operator can revise the direction they
own through the same seam that carries every other artifact — and merge it themselves,
exactly as they already merge a new one.

The direction layer has two writers and no third today: `create.sh` creates, `close.sh`
ends, and nothing edits a live strategy's Aim, Schedule or Assignee. `/specificate`
already recognises a lifecycle announcement by explicit slug — *ended* reaches
`close.sh`, *created* takes the strategy form — and the third branch, *changed*, is
record-only: the ask becomes a feedback record and the operator applies it by hand, on
`main`, in an editor. That is the one act this whole direction says the person still
does, and the one act the loop offers nothing for.

The ask is to route the *changed* announcement to a new `strategy/scripts/amend.sh`
through the publish tree, opening a pull request that carries exactly the revision the
ask named and, like every strategy-touching proposal since 2026-08-14, **does not
auto-merge**. The operator's merge stays the authorship, which is the premise that makes
a third writer admissible rather than a reversal of why there were two.

Bound tightly: only `## Aim`, `target_date` / `## Schedule` and `assignees:` are
revisable. `slug`, `type`, `status`, `created_at`, `author` and the `feedback:` refs are
not — the refs because `attributed-work.sh` walks them and a revision that moved them
would silently re-cut what the direction can see of its own work. A closed strategy is
refused: `close.sh` stays the only writer of an end state.

## Why it says it commits to the strategy

The Aim's closing sentence: *"What a person supplies is no longer the ticket but the
direction: an Aim, a Schedule, an Assignee. Enriching that is the work that is left."*
Every mission attributed to the direction so far has gone into the execution half. The
direction layer has been made readable (`survey-strategies.sh`, `direction-state.sh`,
`attributed-work.sh`, `direction-health`) and is still not maintainable.

The gap is dated: this strategy's own `target_date` is 2026-08-31. When it passes,
`survey-strategies.sh` reports `overdue`, `/propose` refuses it `past_target_date`, and
`/moderate` asks its assignee to re-date or close it. Closing has a path; re-dating does
not — the operator's only route is a hand-edit on `main`. The artifact's own model
already claims a strategy is "outbound, revisable until closed, dated, owned".

## What it is chosen against

Another turn of the execution half (hardening `queue_drained` residue, the two-branch
resolution, the gaps around `report_undelivered`) — refused because that half has had
nine consecutive missions while the direction layer has had none. The fork inside the
mission — making `/moderate`'s overdue question carry a copy-paste command the operator
runs by hand — is refused because it leaves the person editing `main` directly.

What it is not: a licence for a run to edit a direction. No routine calls `amend.sh` on
its own judgement, `/drive` still never surveys a strategy, `/specificate` still matches
by explicit slug only, and the retired `strategy:` relation does not return.

## The plan it names

Eight ordered tickets: write `amend.sh`; route the *changed* announcement to it; pin that
a revision PR can never auto-merge; hold the revised artifact to `validate-strategy.sh`'s
floor; append what moved to `## Schedule` with no new field or store; make
`/moderate`'s overdue and dormant questions name the revision act; drill the four
outcomes with no network; and write the reversal into the three documents that record
"exactly two writers and no third".
