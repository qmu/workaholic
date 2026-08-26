---
type: Feedback
title: Give a mission claim the superseded reading a batch claim already has
kind: insight
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-26T06:56:23+00:00
author: a@qmu.jp
supersedes: 
---

# Give a mission claim the superseded reading a batch claim already has

`claims_superseded` (2026-08-26) answers only for **batch** units: a mission claim
stamps only `mission.md`, which driving never archives, so the reading was left on
`queue_drained` / `parked_with_pr` "for a shape nothing has measured". This tick
measured it, on this repository.

Three mission claims read `stale: true` at 121h with their pull requests **merged**
five days ago — the branches read ahead of `main` only because the merges were
squashes:

- `make-the-draft-release-note-an-agent-s-release-plan` — `work-20260818-205051`,
  PR #521 merged, mission archived, acceptance 3/3, queue 0.
- `make-a-rename-a-registry-entry-not-a-sweep` — `work-20260821-035855`,
  PR #546 merged, mission archived, acceptance 3/3, queue 0.
- `make-workaholify-converge-the-account-s-routines` — `work-20260819-113836`,
  PR #537 merged, mission **still active**, acceptance 2/3, **1 ticket still queued**.

Two consequences, and the second is the one that costs something:

1. `stalled-units` offers all three as candidates on every tick, forever. They are
   finished work, so a question about them is noise — and a step whose candidates
   are mostly noise is a step whose real candidate gets lost.
2. The third one is not residue. Its claim holds the mission's last queued ticket
   out of every survey (`claimed_reported`), so `/implement` can never reach it and
   the mission cannot advance. A finished-and-merged claim silently parks live work.

What is missing is the mission-grain equivalent of the batch reading — a signal that
the unit's content reached the base — derived without a second parser of the
many-valued `mission:` relation, and reported (never acted on) exactly as `stale`
and `superseded` already are. The pull request's own merged state and the mission's
archived state are both readable facts; which of them is the right signal is the
design question, not whether the shape exists.
