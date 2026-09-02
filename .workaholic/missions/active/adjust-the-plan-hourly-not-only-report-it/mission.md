---
type: Mission
title: Adjust the plan hourly, not only report it
slug: adjust-the-plan-hourly-not-only-report-it
status: active
merge_policy:
created_at: 2026-09-01T12:33:32+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260901123318-the-loop-has-clerks-but-no-planner-nothing-re-plans-from-the-live-board-and-convergence-has-no-owner.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260902-083726
---

# Adjust the plan hourly, not only report it

## Goal

The loop has three clerks and no planner: intake adds, execution drives, bookkeeping
reports, and `/propose` only ever ADDS. Nothing reads the whole board and decides what is
next, in what order, or what should stop. Measured in one day: six missions in parallel
with no sequencing, five pull requests conflicting on the loop's own generated index, 30
queued tickets against three directions dated the same day, and a person — not the loop —
converging all of it. The reading landed already; the adjusting never existed.

## Experience

The loop sequences its own work: new divergence is held while too much is in flight, the
executor is offered work in a derived order, converged work is named for closing, and a
date the arithmetic says cannot hold reaches its owner before it passes — never re-dated
by the loop itself.

## Acceptance

- [ ] New divergence is held while work in flight is above a declared limit. (#20260901123357-hold-new-divergence-above-a-work-in-progress-limit.md)
- [ ] The executor is offered work in an order derived from the board, not walk order. (#20260901123357-offer-the-executor-work-in-a-derived-order.md)
- [ ] A date the arithmetic says cannot hold reaches its owner before it passes. (#20260901123357-escalate-a-date-that-will-not-hold-never-re-date-it.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-02 — ticket archived — 20260901123357-say-which-directions-the-arithmetic-says-cannot-land.md
