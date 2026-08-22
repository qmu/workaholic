---
type: Mission
title: Read a strategy's pace against its date
slug: read-a-strategy-s-pace-against-its-date
status: active
merge_policy:
created_at: 2026-08-22T22:51:55+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260822225137-every-propose-gate-is-a-brake-and-none-asks-whether-the-aim-will-be-reached.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Read a strategy's pace against its date

## Goal

All seven `/propose` gates are brakes. None asks whether the direction will arrive, so a strategy
can be perfectly gated — every brake correct, every tick silent for a correct reason — and reach
its date with nothing built. Measured: a platform strategy seven days from its `target_date` whose
19 attributed artifacts were all specification pages, no `tsconfig`, and a deploy config saying
the worker had no code of its own.

`target_date` is read only by `past_target_date` — *it has passed* — never *will it be met*. A
direction heading for an empty date and one on course look identical to the tick.

Three defects fixed on 2026-08-22 shared this root: the missing `describing_move`, record-only
overruling the form precedence, and `over_cap` starving the slowest direction. Each was fixed;
the root was not.

## Experience

A tick reads how far each direction has got against how long it has left, advances the late ones
first, and names a direction that will not arrive rather than being silent about it.

## Acceptance

- [ ] Each surveyed strategy carries a pace reading derived from what has landed and the days
      remaining (#20260822225204-report-a-strategy-s-pace-against-its-remaining-days.md)
- [ ] The tick orders by lateness, and a direction that will not arrive is reported by name (#20260822225204-order-the-tick-by-lateness-and-name-a-direction-that-will-not-arrive.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
