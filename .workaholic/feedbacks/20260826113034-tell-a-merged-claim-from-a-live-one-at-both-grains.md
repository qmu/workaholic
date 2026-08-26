---
type: Feedback
title: Tell a merged claim from a live one at both grains
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-26T11:30:34+00:00
author: a@qmu.jp
supersedes: 
---

# Tell a merged claim from a live one at both grains

Source: https://github.com/qmu/workaholic/issues/623

Opened by the `[Propose]` routine against the strategy
`an-autonomous-improvement-loop-run-by-the-routines`; declared move: contraction.

## What is asked

Make the claim oracle tell a **merged** claim from a live one at **both grains**, and stop
the loop spending a person's attention — or a whole drive cycle — on a unit whose work
already reached `main`.

`claims_superseded` shipped 2026-08-26 (PR #613) and answers only for **batch** units; its
own header names the reason as a shape nothing had measured. The shape has now been
measured on this repository:

- `list-claims.sh` reports 5 claims, 4 stale. Three — `work-20260818-205051`,
  `work-20260819-113836`, `work-20260821-035855` — are the heads of pull requests #521,
  #537 and #546, **all merged**. A squash merge puts none of the branch's commits on the
  base, so `git rev-list --count base..ref` stays positive and the branch is claimed
  forever. All three are **mission** units, so `superseded` is out of scope for every one
  of them by construction.
- The `[Moderate]` tick hands each stale row to the human check-in as a question addressed
  to the claim holder, so a person is being asked to look at finished, merged work.
- `make-workaholify-converge-the-account-s-routines` reads `resumable: true`,
  `resume_reason: parked_with_pr`, while its pull request #537 merged five days ago. A run
  that takes that offer drives onto a dead branch.

What must become true: however a claim's work reached the base — merge commit, squash
merge, rebase, or a recovery onto another branch — the oracle says so, at the mission
grain as well as the batch grain. Such a claim is never offered for resumption and never
becomes a question, and the mission behind it is re-surveyable. The reading stays
`reported, never acted on`, and stays honest when it cannot be made. The answer must not
be a second parser of the many-valued `mission:` relation.
