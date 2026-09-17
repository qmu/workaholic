---
type: Feedback
title: question-liveness retires an escalation key its owning step can never name as a string node
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-09-09T20:24:12+09:00
author: a@qmu.jp
supersedes: 
---

# question-liveness retires an escalation key its owning step can never name as a string node

Measured on moderation tick `20260909-110700`, on this checkout.

A second, distinct cause of the permanent silencing already recorded in
`20260909181740-reconcile-questions-retires-a-live-question-because-the-registry-records-human-checkin-as-every-question-s-owning-step.md`.
That record's cause — the registry storing `human-checkin` as every question's owning step — is
no longer what fires here: the registry now records the correct finding step
(`direction-health`, `closable-missions`, `unanswered-asks`). The silencing still happens.

`question-liveness.sh` matches the key against the owning step's `needs_agent` with

    any((.needs_agent // []) | .. | strings; . == $k)

which is exact equality on a string *node*. A step that names its key only inside prose —
never as a value of its own — can therefore never read `live`.

`step-unanswered-asks.sh` is exactly that step. Its escalation key exists only inside the
`escalation` sentence of its single `needs_agent` entry ("ask ONE question through
ask-question.sh keyed inbound-channel-unreadable:dev-workaholic ..."), because whether the
channel was readable is decided by the *agent* after the run, not by the script. The script
cannot raise the key as a node without asserting a reading it has not made.

Measured this tick, in order:

- `unanswered-asks` reported `ok`, channel `#dev-workaholic`, window 26h.
- `reconcile-questions.sh` read liveness for `inbound-channel-unreadable:dev-workaholic`
  under its correct owning step `unanswered-asks`, got `settled`, and retired the key with
  evidence `owning_step_resolved_premise` (registry revision 24).
- `ask-question.sh --key inbound-channel-unreadable:dev-workaholic` now answers
  `{"ask":false,"reason":"premise_resolved","hold":false}`.
- The channel was in fact unreadable in the same tick: the declared binding
  (`AGENTS.md`, workspace `qmu`, channel `dev-workaholic`) resolved
  `deferred / operations_unsatisfied` — the described QFS route offers
  `read_channel_delta, read_thread, search_exact, post_reply` and the declaration requires
  `post_root`, `list_thread_changes` and `add_reaction` as well.

So the one question whose whole purpose is to tell a person the loop cannot read its own
channel was retired by the reconciler in the same tick the channel could not be read, and it
can never be asked again. A retired key is a permanent silence, which is why this class of
retirement must be conservative.

`reference/workflow.md` already states the standard this violates: `unknown` is load-bearing,
and "a wrong guess would answer `settled` about a subject nobody looked at — the one answer
this script must never invent." Here the guess is not about which step, but about what a
step's silence means.

The repair the finding names, in the order of preference the existing contracts support:

1. A step whose candidate set is decided by the agent must be able to say so. Let such a step
   report its escalation key as its own string node under a field the matcher can see (a
   `pending_keys[]`), or let `question-liveness.sh` answer `unknown` — never `settled` — for a
   step whose `needs_agent` hands the agent the decision.
2. Failing that, the reconciler must not retire on `settled` alone for a step that returned a
   `needs_agent` entry at all: a step still asking the agent for a reading has not resolved a
   premise.

Nothing was retired, re-asked or rewritten by this report. The registry entry retired this
tick is left as it is; naming it is the act.
