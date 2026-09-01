---
type: Feedback
title: Deliver and retire what the loop already proved finished
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-27T05:20:27+00:00
author: a@qmu.jp
supersedes: 
---

# Deliver and retire what the loop already proved finished

The `[Propose]` routine asks the loop to **act** on the two claim readings that are proofs, instead of reporting them to a person and stopping.

Source: https://github.com/qmu/workaholic/issues/649

Both readings landed this week and both stop at a report:

- `report_undelivered` (2026-08-27) means the loop finished a unit and the transport refused its merge. The run that attempted it retries once in-session under the one named precondition; no later run ever retries. `plan-units.sh` excludes the unit `claimed_undelivered` at every later survey, `claim.sh resume` refuses it by its own name, and `/moderate`'s `undelivered-units` step asks a person. So a green, finished, undelivered unit is delivered by nobody until a human opens the pull request and presses the button.
- `superseded` (2026-08-26) means the claim's content already reached the base — a proof, not a suspicion. It is "reported, never acted on". What nothing does is retire the claim itself — its branch, its worktree and its open pull request stay forever, so the claim table only ever grows. Measured on this repository today: 7 claims, 4 of them `superseded`, two of those naming missions archived days ago, the oldest branch last touched 2026-08-21.

What must become true:

1. Which claim verdicts are **proofs** and which are **judgements** is written down once and read by every consumer — never re-derived. `superseded` and `report_undelivered` are proofs; `stale`, `queue_drained`, `report_incomplete`, `ambiguous_claim` and `unanswerable` stay judgements.
2. A later driving run re-attempts the merge of a `report_undelivered` unit, through the same seam that refused it, and records the new outcome on the branch story it already reads. It never overrides a gate: a `hard` or `confirm` scan finding is a pull request waiting on a person by design, not a refused delivery.
3. A claim proved `superseded` is retired by one writer — its pull request closed, its remote branch deleted, its worktree reaped — after the tick re-proves the verdict itself. Nothing merges, nothing touches a live claim, and a row the re-proof rejects is reported, not retired.

Named seams: `drive/scripts/lib/claims.sh` and `drive/reference/claims.md` for the verdict table, `drive/scripts/plan-units.sh` and the `/implement` route for the delivery retry, `story/scripts/record-merge-outcome.sh` for the recorded outcome, a new `drive/scripts/retire-claim.sh` as the one retirement writer, and a new `/moderate` step beside `undelivered-units` as its only caller.

Why it commits to the strategy: the Aim's completion condition is a turn that closes unattended. A unit the loop finished and could not deliver is a turn that did not close — the work exists, the pull request is green, and the direction sees nothing, because attribution reads the base. Every reading shipped against this direction in the last week made the loop see further, and each one's terminal act is *ask a person* or *report it*.

Chosen against: bringing the unattributed backlog into the light. It loses now because it is another reading, and it would deepen the exact imbalance being corrected here.

The narrower fork inside the mission is taken deliberately: retire only what is proved. Closing a `stale` claim, or deleting a branch behind a `queue_drained` one, is refused — those readings are judgements.
