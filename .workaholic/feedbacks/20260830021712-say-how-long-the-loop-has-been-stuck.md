---
type: Feedback
title: Say how long the loop has been stuck
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-30T02:17:12+00:00
author: a@qmu.jp
supersedes: 
---

# Say how long the loop has been stuck

Say how long the loop has been stuck.

Source: https://github.com/qmu/workaholic/issues/740

The `[Propose]` routine asks for a reading of **how long a condition has held**, derived
from the tick log the loop already writes, and for that term to ride the questions the tick
already asks.

Every reading in this repository is instantaneous — a claim's verdict, a residue, an
undrivable unit, a blocked retirement, an unanswered ruling — and nothing composes *this has
been true since*. The store-free property is deliberate and must not be reversed, but the loop
is not actually store-free: `.workaholic/moderations/<UTC-day>.md` is append-only, hourly,
committed to the base, and already read back by `log-read.sh`, `question-state.sh`,
`filed-records.sh` and the day cap. A condition's age is derivable from a store that exists.

What must become true:

- One reader answers *how long*, composing `log-read.sh` over the day files and owning nothing
  else: given a step id and the subject key that step already uses, the earliest tick whose
  summary named that subject, the tick count since, and `readable: false` with null counts when
  the log could not be read. No new store, no cursor, no field on any artifact, no second walker.
- The walk is bounded, because the log is never pruned, and a bounded walk says so: a truncated
  read reports `first_seen` as *at least*, never as a date it could not establish.
- The questions that name a standing blocker carry the term — `undrivable-unit`,
  `retire-blocked`, `undelivered-unit`, `stalled-unit` — each keyed on the subject it already
  has, so no key, cap or hold moves and nothing is re-asked by the changed wording.
- `operator-pull` keeps reading the pull request's own `created_at`, and the one place that
  says which questions read which source says it explicitly, so the two readings cannot drift.
- The run reports of `/implement` and `/propose` name it in the voice `pace`, `expiring` and
  `arrived` are named in: evidence, never a verdict.
- Every value is a judgement, classified in one place with its enumerated consumers, and the
  suite fails when a consumer acts on it. No gate, hold, re-ask, escalation, merge, claim or
  sort may read the age.

Measured on this repository at the hour the ask was written: five queued tickets across three
missions are stamped with an address the identity mapping does not name and have been
undrivable since 2026-08-19 — eleven days. Three proved-superseded branches still stand. One
ruling pull request (#694) has been open twenty-five hours holding the mapping line that would
release those five tickets. The loop sees every one of these, at four separate surfaces, and
its questions about them were each asked once, days ago, and by the asked-once gate will never
be asked again.

The move is chosen against releasing a standing ruling's hold when it goes unanswered: a
release on a timer is refused by name in this layer, and any release rule written today would
rest on a fresh constant nobody can defend, because nothing in the loop can currently state how
long anything has been true. Build the reading first.

The counter-argument is recorded rather than dismissed: the store-free property is real, the
tick log is never pruned so the walk gets more expensive forever, and a duration term invites
precisely the timer-based gates this layer has refused four times. The bound answers the second;
the judgement classification with its enumerated consumers and its pin answers the third.
