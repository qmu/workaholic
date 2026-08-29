---
type: Mission
title: Make a direction's lifecycle a declared stage
slug: make-a-direction-s-lifecycle-a-declared-stage
status: active
merge_policy:
created_at: 2026-08-29T21:20:01+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260829211659-make-the-strategy-lifecycle-staged.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260829-212940
---

# Make a direction's lifecycle a declared stage

## Goal

A direction's lifecycle reads as converged-or-not — `quiescent`, `dormant`,
`no_evolutionary_move`, all **derived**. The operator asks for a **declared**
phase in their own words: 進行中 (not yet cut over), 改良中 (cut over, still
improving) and 観察中 (settled; reactive only). Directions improve as a blend,
and the stage says where the loop's energy belongs.

## Experience

Every active direction shows **one declared word** wherever directions are
read, and it changes only when the operator announces it. `/propose` proposes
against 進行中 and 改良中 and originates nothing against 観察中. When evidence
suggests a boundary was crossed, one person is asked; no machine moves it,
and stuckness never reads as 観察中.

## Acceptance

- [x] A direction carries a declared stage in the operator's own vocabulary,
      written only by an act the operator announced. (#20260829212056-let-the-operator-move-a-stage-through-the-loop.md)
- [ ] The stage drives `/propose`: 観察中 originates nothing, 進行中 and 改良中
      keep proposing, and 改良中 competes for priority across directions. (#20260829212056-order-an-improving-direction-against-its-rivals.md)
- [ ] A suggested transition reaches the person who can declare it, and no
      stage is ever inferred from a handoff, a block or an undecided unit. (#20260829212056-ask-a-person-when-the-evidence-suggests-a-transition.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-29 — ticket archived — 20260829212056-record-a-direction-s-declared-stage-on-the-artifact.md
- 2026-08-29 — ticket archived — 20260829212056-let-the-operator-move-a-stage-through-the-loop.md
