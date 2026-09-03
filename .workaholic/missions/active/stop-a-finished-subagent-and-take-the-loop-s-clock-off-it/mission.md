---
type: Mission
title: Stop a finished subagent and take the loop's clock off it
slug: stop-a-finished-subagent-and-take-the-loop-s-clock-off-it
status: active
merge_policy:
created_at: 2026-09-03T07:10:15+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260903070805-the-loop-keeps-a-finished-subagent-alive-as-its-clock-so-no-run-starts-from-a-fresh-context.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260903-145115
---

# Stop a finished subagent and take the loop's clock off it

## Goal

The operator's intent is that a subagent is discarded when its work finishes, so every run starts
on a fresh context window. `/infinite-development` specifies the opposite: an idle agent is the
loop's clock, so it is reaped at the next spawn. An idle agent is a resumable session holding its
whole transcript — measured twice, a send woke one inside its prior context. And nothing bounds a
run: one `implement` agent lived 90 minutes and planned a second mission inside the first one's.

## Experience

A finished run holds no context window: the tick stops it at the head of the next tick, whatever
any cadence says. Each loop's cadence is read from a recorded finish time rather than a live
agent's start age, and an `/implement` run takes one PR-unit and ends.

## Acceptance

- [x] A finished subagent is stopped at the head of the next tick whatever its cadence reads,
      and the listing carries only running runs. (#20260903071053-reap-every-idle-subagent-at-the-head-of-the-tick.md)
- [x] Each loop's cadence is derived from a recorded finish time, never from an idle agent's
      `started` age. (#20260903071053-read-each-loop-s-cadence-from-the-recorded-finish.md)
- [ ] An `/implement` run takes one PR-unit and ends, so no context spans two missions. (#20260903071053-bound-an-implement-run-to-one-pr-unit.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-03 — ticket archived — 20260903071053-record-each-loop-run-s-finish-on-the-tick-log.md
- 2026-09-03 — ticket archived — 20260903071053-read-each-loop-s-cadence-from-the-recorded-finish.md
- 2026-09-03 — ticket archived — 20260903071053-reap-every-idle-subagent-at-the-head-of-the-tick.md
