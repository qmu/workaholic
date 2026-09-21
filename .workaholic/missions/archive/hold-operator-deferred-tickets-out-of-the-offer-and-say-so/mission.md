---
type: Mission
title: Hold operator-deferred tickets out of the offer and say so
slug: hold-operator-deferred-tickets-out-of-the-offer-and-say-so
status: achieved
merge_policy:
created_at: 2026-09-21T18:03:58+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260921180339-exclude-explicitly-deferred-tickets-from-the-claimable-offer.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260921-191811
---

# Hold operator-deferred tickets out of the offer and say so

## Goal

An operator defers a queued ticket in prose, so every tick claims it again and rediscovers the
same instruction. `status: icebox` exists but is an **archive** state filtered out inside
`list-todo.sh`, below the survey — so a deferred ticket is invisible rather than held, and a
queue emptied by deferral reads exactly like an empty one.

## Experience

An operator adds one declaration to a queued ticket. The next survey still counts it in
`backlog_size`, offers it to nobody, and names it in `excluded[]` with its own reason. The tick
says the queue is held rather than empty, spawns no runner for it and reports no failure.
Removing the declaration is the only thing that makes it claimable again.

## Acceptance

- [x] A malformed declaration is refused at write time; a valid one is offered by no survey.
      (#20260921180418-declare-an-operator-deferral-on-a-queued-ticket.md)
- [x] `plan-units.sh` counts it in `backlog_size` and names it in `excluded[]` with its own
      reason, which `backlog_all_excluded` reports and counts.
      (#20260921180418-name-a-deferred-ticket-in-the-survey-exclusions.md)
- [x] A deferred-only queue takes zero runners, is named, and is neither `readable: false` nor
      a failure. (#20260921180419-stop-a-deferred-only-queue-consuming-a-runner.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-21 — ticket archived — 20260921180418-declare-an-operator-deferral-on-a-queued-ticket.md
- 2026-09-21 — ticket archived — 20260921180418-name-a-deferred-ticket-in-the-survey-exclusions.md
- 2026-09-21 — ticket archived — 20260921180419-stop-a-deferred-only-queue-consuming-a-runner.md
- 2026-09-21 — mission achieved — mission.md
