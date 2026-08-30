---
type: Mission
title: Say how long the loop has been stuck
slug: say-how-long-the-loop-has-been-stuck
status: active
merge_policy:
created_at: 2026-08-30T02:20:49+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260830021712-say-how-long-the-loop-has-been-stuck.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260830-024048
---

# Say how long the loop has been stuck

## Goal

Every reading in this repository is instantaneous: each says **what** is stuck and none
says **how long**. Give the loop one reader that answers a condition's age from the tick
log it already writes, put that term on the questions that name a standing blocker, and
classify every value as a judgement nothing may act on. No new store, no cursor, no field
on any artifact, no second walker.

## Experience

When the tick asks a person about a standing blocker, the question names how long that
blocker has held. Someone reading one question can tell a condition that started this hour
from one that has been true for eleven days, and the run reports carry the same term. A log
that could not be read is named as unreadable and never rendered as *this just started*.
Nothing gates, holds, re-asks, escalates or merges on the age.

## Acceptance

- [x] One bounded reader answers a condition's age from the tick log, with null counts and
      a named reason on a degraded read, and a truncated walk reported as *at least*. (#20260830022138-bound-the-age-walk-and-say-when-it-was-bounded.md)
- [x] The four standing-blocker questions carry the term on their existing keys, with no
      key, cap, hold or step summary moved. (#20260830022138-carry-the-age-on-stalled-unit-and-state-the-two-sources.md)
- [ ] Every value is classified a judgement in one home with its enumerated consumers, the
      suite fails when one acts on it, and an offline drill proves the chain. (#20260830022138-drill-the-condition-age-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-30 — ticket archived — 20260830022138-read-a-condition-s-age-from-the-tick-log.md
- 2026-08-30 — ticket archived — 20260830022138-bound-the-age-walk-and-say-when-it-was-bounded.md
- 2026-08-30 — ticket archived — 20260830022138-carry-the-age-on-the-undrivable-unit-question.md
- 2026-08-30 — ticket archived — 20260830022138-carry-the-age-on-retire-blocked-and-undelivered-unit.md
- 2026-08-30 — ticket archived — 20260830022138-carry-the-age-on-stalled-unit-and-state-the-two-sources.md
