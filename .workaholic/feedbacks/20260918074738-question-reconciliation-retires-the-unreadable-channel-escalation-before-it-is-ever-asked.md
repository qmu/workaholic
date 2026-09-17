---
type: Feedback
title: Question reconciliation retires the unreadable-channel escalation before it is ever asked
kind: concern
source: development
subject: observer_ai:[Moderate] tick 20260917-223112
created_at: 2026-09-18T07:47:38+09:00
author: a@qmu.jp
supersedes: 
---

# Question reconciliation retires the unreadable-channel escalation before it is ever asked

The moderation tick's question reconciliation retires the one question that reports an
unreadable inbound channel, before that question has ever been asked, and the retirement is
structurally guaranteed rather than occasional.

Measured on tick `20260917-223112` in this checkout, in the order it happened:

1. `question-state.sh --key inbound-channel-unreadable:dev-workaholic` read `never_asked` —
   no ledger line had ever been spent on it.
2. `/moderate`'s own command body instructs a run to call `reconcile-questions.sh --input <file>`
   with the completed run *before offering questions*. That call retired the key, writing
   `state: retired` with `evidence: {proved: true, reason: "owning_step_resolved_premise"}`.
3. `ask-question.sh` now answers `{"ask": false, "reason": "premise_resolved", "hold": false}`
   for it. `premise_resolved` is the one refusal that does not hold, so the question is not
   deferred — it is gone.
4. The premise had not resolved. In the same tick, `describe-qfs.sh` verified channel
   `C0BLL9J7FMY` on two routes (`/slack` account `team`, `/slack-cc-for-qmu` account
   `cc-for-qmu`) offering `read_channel_delta` / `read_thread` / `search_exact` only;
   `resolve-target.sh` refused the read-only binding `ambiguous_identity` (both accounts,
   `sender_id: null`); and the Slack connector read of that channel was denied by the harness
   permission classifier. The channel could not be read.

Why it is structural, not a one-off. `question-liveness.sh` answers `live` only when the owning
step's `needs_agent` payload carries the question key as an **exact JSON string**. The escalation
is the *agent's* decision, taken after the step ran, so `step-unanswered-asks.sh` cannot name it
as a candidate: its payload mentions the key only inside the `escalation` sentence. Measured on
this run's JSON — the key matches as a substring (`true`) and as an exact string (`false`), so
the verdict is `settled` whatever the channel's real state, and the retirement follows every
tick. `question-registry.sh` then makes it permanent: `register` merges only
`step`/`coordinate`/`subject` over an existing row and keeps `state: retired`, and the `asked`
event is a no-op on a retired key.

The consequence is a silent one. `unanswered-asks` is classified `needs_ruling` precisely because
"a channel the tick could not read is a connector, a token or a name only a person can fix, and
it reaches that person as the keyed `inbound-channel-unreadable:<channel>` question rather than
as a filed issue". That is now the one route the reading has, and it is closed. The channel has
been unreadable since at least 2026-09-02, and eight open issues (#806, #939, #1095, #1101,
#1106, #1114, #1167, #1184) restate the write half of the same incident.

Two things this record does not claim. It does not say which repair is right — narrowing the
liveness match, excluding agent-raised escalation keys from reconciliation, or requiring a
retirement's evidence to be a positive reading rather than the absence of one, are different
changes with different costs. And it does not say the retirement was wrong to attempt: the run
followed the command body's own instruction, which is why the defect had never been observed
from inside a tick before.
