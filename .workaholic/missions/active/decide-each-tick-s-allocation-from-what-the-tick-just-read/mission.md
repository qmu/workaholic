---
type: Mission
title: Decide each tick's allocation from what the tick just read
slug: decide-each-tick-s-allocation-from-what-the-tick-just-read
status: active
merge_policy:
created_at: 2026-09-03T07:20:35+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.7
feedback: [20260903071947-the-tick-walks-three-names-in-order-instead-of-allocating-capacity-to-where-the-work-is.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260906-002101
---

# Decide each tick's allocation from what the tick just read

## Goal

The tick's allocation is a constant and the loop's state is not, so the bottleneck never gets
capacity and the runner with nothing to do is walked anyway. Measured over two hours: 54 tickets
across 8 active missions, **one** `implement` runner by construction — the concurrency rule
forbids a second — about seven hours of serial queue; and `propose`'s strategy half produced no
proposal, re-deriving a gate only `implement` clears.

## Experience

The tick puts the session's capacity where the work is. It reads what is independently claimable
and fans out `implement` runners up to a declared bound, ingests an ask the moment its own sweep
captured one, does not walk a runner whose last answer cannot have moved, and reports what it
chose.

## Acceptance

- [x] A tick fans out one `implement` runner per independently claimable unit, up to a bound the
      repository declares; absent means the present single runner. (#20260903072108-fan-out-one-implement-runner-per-claimable-unit.md)
- [x] The ingest half runs on the tick's own capture, and the strategy half keeps its cadence. (#20260903072108-run-the-ingest-half-on-the-tick-s-own-capture.md)
- [x] The tick reports the allocation it chose and why, including a tick that chose to watch. (#20260903072108-report-the-allocation-the-tick-chose-and-why.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-03 — ticket archived — 20260903072107-read-what-is-independently-claimable-this-tick.md
- 2026-09-03 — ticket archived — 20260903082012-read-the-machine-s-cores-and-load-average.md
- 2026-09-03 — ticket archived — 20260903072108-fan-out-one-implement-runner-per-claimable-unit.md
- 2026-09-03 — ticket archived — 20260903072108-run-the-ingest-half-on-the-tick-s-own-capture.md
- 2026-09-03 — ticket archived — 20260903072108-skip-a-runner-whose-last-answer-cannot-have-moved.md
- 2026-09-03 — ticket archived — 20260903072108-report-the-allocation-the-tick-chose-and-why.md
- 2026-09-03 — run recorded (+0.7h) — implement-20260903-093600
- 2026-09-06 — ticket archived — 20260903072108-declare-the-fan-out-bound-for-implement-runners.md
- 2026-09-06 — ticket archived — 20260903082013-refuse-a-fan-out-the-machine-cannot-carry.md
