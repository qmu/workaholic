---
type: Mission
title: Pay only the operative cost on every tick
slug: pay-only-the-operative-cost-on-every-tick
status: active
merge_policy:
created_at: 2026-09-03T07:16:57+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260903071448-the-tick-s-fixed-cost-is-paid-every-five-minutes-and-most-of-it-answers-nothing.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260903-142217
---

# Pay only the operative cost on every tick

## Goal

The loop runs forever, so its fixed per-tick cost is the number that matters and it is larger
than the work most ticks do. Measured over two hours: ~23 ticks, 4 capturing an ask, the rest
quiet. `log-read.sh` returns the whole day (50,087 bytes at two hours) to answer one timestamp;
`commands/infinite-development.md` is 11,291 bytes re-paid every five minutes in a session that
never resets; a run's result reaches the parent twice; a quiet tick still prints six lines; and
the channel read asks for metadata the tick never uses.

## Experience

A tick pays for what it does. The cadence gate reads one line, the command body carries the
operative instructions with its record beside it, a result arrives once, a tick that swept,
reaped and spawned nothing says one line, and the channel read asks for what the tick uses.

## Acceptance

- [x] The `moderate` cadence gate reads one line rather than the day's log. (#20260903071726-answer-the-cadence-gate-with-one-line-not-the-day.md)
- [ ] The command body carries only what a run must read to act; its measurements and rejected
      alternatives move to a `reference/` page with nothing lost. (#20260903071726-split-the-tick-command-into-operative-text-and-record.md)
- [ ] A quiet tick reports one line and a run's result reaches the parent once. (#20260903071726-say-nothing-at-length-on-a-tick-that-did-nothing.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-03 — ticket archived — 20260903071726-answer-the-cadence-gate-with-one-line-not-the-day.md
