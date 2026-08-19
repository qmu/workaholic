---
type: Feedback
title: Fix the housekeep check-in's already-asked gate
kind: instruction
source: development
subject: observer_ai:tamurayoshiya
created_at: 2026-08-19T06:19:02+00:00
author: a@qmu.jp
supersedes: 
---

# Fix the housekeep check-in's already-asked gate

# Fix the housekeep check-in's already-asked gate

Source: https://github.com/qmu/workaholic/issues/529

The `/housekeep` check-in's `already_asked` gate cannot see a question it already asked,
so the tick would re-post the same question every hour — the nagging
`housekeep/reference/workflow.md` §9 forbids ("Silence is not consent, and it is not a
reason to ask again. An unanswered question is never re-posted.").

Two independent causes, both in `housekeep/scripts/ask-question.sh`'s three-line gate:

1. **The dedup reads the summary, not the step id.** `already=$(count_log_prefix
   human-checkin-ask "$KEY")` passes the key to `log-read.sh --contains`, whose own header
   states `--contains` is "a plain substring match over the **summary**". The summary is
   agent-composed prose, so whether it contains the raw key is a property of the agent's
   wording rather than of the code — a gate the skill documents as mechanical is in fact
   caller discipline.
2. **The step id is truncated below the key length.** `SLUG` is `cut -c1-32`, so a key
   longer than 32 characters yields a step id that does not contain its own key. Even if
   `--contains` matched the step id, the gate would still miss for those keys.

Measured: tick `20260819-045108` asked `ask:issue-524-unassigned-never-ingested` at 13:53
JST and logged it under step `human-checkin-ask-issue-524-unassigned-never-inges` (49
chars; the slug lost the trailing `ted`). One hour later, tick `20260819-055208` ran the
same key and got `{"ask": true, ..., "asked_this_tick": 0, "asked_today": 3}` — `ask: true`
for a question asked an hour earlier and still sitting unanswered in `#dev-workaholic`.
That tick did not re-post it (the contract in prose stopped what the gate did not), but the
gate is the thing the contract says is doing the work. `day_cap` (10) is the only backstop
left, so at five questions a tick the ceiling is ten copies of one question per day.

Considered and rejected by the reporter: widening `--contains` to match the step id (fixes
cause 1 only, and changes a shared reader every step's dedup uses for one caller's
benefit); lengthening the `cut -c1-32` (fixes cause 2 only, and only to the new bound).

Suggested direction: give `log-read.sh` an exact step-id query and have `ask-question.sh`
ask for its own computed `LOG_STEP` rather than for the key — the step id is derived from
the key by the same function on the write and the read side, so the match becomes an
identity rather than a substring search over prose. Truncation then stops mattering for
correctness, though two keys sharing a 32-character prefix would collide, which is worth a
length check or a short hash suffix in the same change.

Filed by the housekeep tick about its own machinery; it performed nothing and posted no
question that tick.
