---
type: Feedback
title: The draft-gate proposal's replacement gate is the one this repo just measured as broken
kind: concern
source: discussion
created_at: 2026-07-30T18:24:36+09:00
author: a@qmu.jp
supersedes: 
---

# The draft-gate proposal's replacement gate is the one this repo just measured as broken


The draft mission `drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main`
proposes to remove `plan-units.sh`'s `not_approved` exclusion and make `no_plan` (acceptance
`total == 0`) **the sole quality gate on the offer**, on the stated premise that "a mission is
drivable when it has a plan, not when someone said so."

That premise is measurably false today, and the mission is itself an instance of the
counter-example.

`no_plan` counts `## Acceptance` **items**, not queued **tickets**, and `/propose` writes a
provisional acceptance sketch into exactly that section. So a proposal satisfies the gate with
zero tickets. Two live proofs, both observed on 2026-07-30 by a `/drive` survey against a current
`main`:

- `adopt-a-git-flow-branching-model-with-durable-ship-records` — `status: approved`,
  `merge_policy: auto`, `tickets: []`, `0/8` acceptance whose own first line reads *"PROPOSED
  sketch for discussion — not a plan."* It is offered as a claimable PR-unit right now. A runner
  claiming it creates a branch and worktree, finds an empty queue, and holds authority to merge.
- `drop-the-draft-gate-…` itself — `0/9` acceptance, `tickets: []`. Approving it as written would
  remove the one exclusion currently keeping it out of the offer, and leave behind a floor that
  admits it.

So the ordering matters: **the replacement gate has to be fixed before the current gate is
removed**, or the change lands the exact empty-queue claim it assumes cannot happen. Ticket
`20260730181500-plan-floor-counts-acceptance-not-queue.md` (queued) makes "has a plan" mean "has a
queue" via a single reader both `plan-units.sh` and `approve.sh` call, with a distinct
`excluded[]` reason. That ticket is the prerequisite, not a parallel nicety.

Two further notes for whoever replans this mission:

- **Its worktree half is already done.** PR #108 (decision J1/J3) made artifact creation publish to
  `main`, left `claim.sh` as the only creator of a branch or worktree, and added the
  fast-forward-before-survey step — which is what "own its worktree from refreshed main" asks for.
  Re-check that half against the merged code rather than the sketch before emitting tickets for it.
- **The `approve.sh` floor is not only about drivability.** It is where a human asserts that every
  judgement call about *these exact tickets* was answered, and it records the `merge_policy`
  ruling. Retiring `draft` retires that seam too, so the replan should say where the merge-policy
  ruling goes — `auto` is not a default anything should acquire by omission.
