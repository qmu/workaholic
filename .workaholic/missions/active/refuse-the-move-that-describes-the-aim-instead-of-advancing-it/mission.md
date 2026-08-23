---
type: Mission
title: Refuse the move that describes the aim instead of advancing it
slug: refuse-the-move-that-describes-the-aim-instead-of-advancing-it
status: active
merge_policy:
created_at: 2026-08-22T19:47:20+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260822194700-the-loop-refuses-housekeeping-but-not-documentation-so-a-build-strategy-produces-only-documents.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260823-155258
---

# Refuse the move that describes the aim instead of advancing it

## Goal

A strategy whose Aim is to **build** an application platform produced, over weeks, only
documents: three missions citing its own ref, every ticket a page, and a deployment config whose
own comment says the worker has no code of its own. `/propose` refuses housekeeping and cannot
refuse documentation — a page *about* the Aim is a perfect `depth` move against it. Those pages
then attribute to the strategy, `work_waiting` reads them as progress, and nothing else is
proposed until they merge. The cycle sustains itself.

The one ask that should have broken it — *revise the strategy so it drives implementation* —
named nine buildable components and was judged **record-only**, against the skill's own
precedence that a decomposable direction is planned.

## Experience

A proposal that would produce documentation about an Aim whose subject is to build something is
refused by name. A strategy carrying only descriptive work does not read as one with work in
flight. A decomposable ask is planned, and the run says which rule decided.

## Acceptance

- [x] A decomposable ask reaches a mission rather than record-only, and the deciding rule is named (#20260822194728-let-the-precedence-rule-beat-the-record-only-default.md)
- [x] A describing move against a building aim is refused by name (#20260822194728-refuse-a-describing-move-against-a-building-aim.md)
- [ ] A strategy with only descriptive work attributed to it is not gated as work-in-flight (#20260822194728-tell-describing-work-from-advancing-work.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-22 — ticket archived — 20260822194728-let-the-precedence-rule-beat-the-record-only-default.md
- 2026-08-22 — ticket archived — 20260822194728-refuse-a-describing-move-against-a-building-aim.md
