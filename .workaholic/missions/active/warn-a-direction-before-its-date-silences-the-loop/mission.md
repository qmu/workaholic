---
type: Mission
title: Warn a direction before its date silences the loop
slug: warn-a-direction-before-its-date-silences-the-loop
status: active
merge_policy:
created_at: 2026-08-29T02:18:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260829021712-warn-a-direction-before-its-date-silences-the-loop.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260829-024033
---

# Warn a direction before its date silences the loop

## Goal

Every reading in the layer answers backwards — `late`, `overdue`, `dormant`,
`arrived`. None answers *this direction is about to stop originating work*, so
`past_target_date` silences `/propose` unwarned and the only signal is
`direction-overdue`, asked in arrears. `expiring` is that reading, derived from
terms already on the row.

## Experience

A direction is never silenced by its own date without its owner being told
first. A live direction inside its last window reads `expiring` on its survey
row and in its lifecycle reading, and its assignee is asked once — naming the
date, the days left and the leaving — so they can re-date it, close it with a
successor, or let it end through the existing seams. A direction outside the
window reads as today, an already-overdue one still reads `overdue`, and no
machine re-dates, closes or amends a direction.

## Acceptance

- [x] `expiring` is emitted on every surveyed row and ranked in the lifecycle
      precedence, with the leaving carried onto it. (#20260829021946-emit-expiring-on-every-surveyed-row.md)
- [ ] The assignee is asked `direction-expiring:<slug>` once, before the date,
      under every existing gate and hold. (#20260829021947-ask-the-assignee-once-before-the-date.md)
- [ ] A hermetic diff pins that no gate, sort, refusal or token moved. (#20260829021947-name-expiring-in-the-run-report-as-evidence.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-29 — ticket archived — 20260829021946-reproduce-the-silent-expiry-and-pin-it.md
- 2026-08-29 — ticket archived — 20260829021946-emit-expiring-on-every-surveyed-row.md
- 2026-08-29 — ticket archived — 20260829021946-rank-expiring-in-the-lifecycle-reading.md
