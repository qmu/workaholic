---
type: Mission
title: Emit a mission only when there is a mid-term plan to hold
slug: emit-a-mission-only-when-there-is-a-mid-term-plan-to-hold
status: active
merge_policy:
created_at: 2026-09-03T05:36:16+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260903053558-a-mission-is-the-mid-term-container-not-an-envelope-around-one-ask.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260903-104341
---

# Emit a mission only when there is a mid-term plan to hold

## Goal

The operator restated the grain: a mission is the mid-term container between a strategy and a
ticket, with room to plan tickets across a period. The corpus does not match it — 94 missions,
one with a single ticket, 21% at four or fewer, 52% at exactly seven or eight. Two mechanisms
produce that: one mission per inbound ask, and a scale written as a count to hit.

## Experience

A mission exists because there is a mid-term plan to hold, never because an ask arrived. One
below two tickets cannot be written at any seam; an ask too small becomes a loose ticket or the
record, and the run says which; and the scale is stated as what the container must hold.

## Acceptance

- [x] A mission below two tickets cannot be written at any seam, and the ones already on disk
      are named rather than rewritten. (#20260903053712-floor-a-mission-at-two-tickets-at-every-seam.md)
- [ ] `/specificate` emits a mission only when it judges a mid-term plan is there, and reports
      what a smaller ask became instead. (#20260903053713-judge-whether-an-ask-has-a-mid-term-plan-in-it.md)
- [x] The scale is stated once as what the container must hold, and no surface names a ticket
      count to hit. (#20260903053712-state-what-a-mission-must-be-able-to-hold.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-03 — ticket archived — 20260903053712-state-what-a-mission-must-be-able-to-hold.md
- 2026-09-03 — ticket archived — 20260903053712-floor-a-mission-at-two-tickets-at-every-seam.md
