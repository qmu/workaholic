---
type: Feedback
title: reconcile-questions retires a live question because the registry records human-checkin as every question's owning step
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-09-09T18:17:40+09:00
author: a@qmu.jp
supersedes: 
---

# reconcile-questions retires a live question because the registry records human-checkin as every question's owning step

Measured on moderation tick `20260909-085038`, on this checkout.

`reconcile-questions.sh` walks every open question in the runtime registry and, for each,
calls `question-liveness.sh --key <key> --step <the registry's own `step` field>`. The
registry records `step: "human-checkin"` for every question, because `ask-question.sh` is
what registers the preimage and it is the check-in's gate. But `question-liveness.sh`
answers from the **owning step's** `needs_agent` in the tick's run report, and the owning
step of a finding is the step that *found* it, not the step that asks it.

`reference/workflow.md` states this exactly: "The owning step is an **argument**, not a
guess from the key's prefix ... a wrong guess would answer `settled` about a subject nobody
looked at." The registry's stored `step` is that wrong guess, applied to every key.

What it cost this tick, measured:

- `closable-missions` raised `mission-leftovers:turn-quiescent-blockers-into-mature-decisions-and-resume-work`
  live, with `checked 3/3` and 1 ticket still queued.
- `reconcile-questions.sh` read liveness for that key under step `human-checkin`, which did
  not name it, and retired it with evidence `owner_step_resolved_premise`.
- `ask-question.sh` now refuses the key `{"ask":false,"reason":"premise_resolved"}`.
  A retired key can never be re-asked, so the question is silenced permanently while the
  condition it names is still true in the tree.

Verified directly, same run report:

    --key mission-leftovers:...  --step human-checkin      -> settled
    --key mission-leftovers:...  --step closable-missions   -> live

The three keys that survived this tick did so by coincidence, not by design: they appear as
literal strings inside `human-checkin`'s own `needs_agent.held[]` array, which is what the
liveness matcher searches. Any question whose finding step is not `human-checkin` and whose
key is not echoed in the held list is retired the first time it is reconciled.

The repair the finding names: record the **finding** step on the question at registration
(`ask-question.sh --asked-step` already carries it, and `reconcile-questions.sh` should read
that rather than the registry's `step`), or have the reconciler resolve liveness against the
whole run report rather than one named step. It must not retire on an owning step it guessed.
