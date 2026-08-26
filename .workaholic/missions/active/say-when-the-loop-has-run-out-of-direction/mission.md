---
type: Mission
title: Say when the loop has run out of direction
slug: say-when-the-loop-has-run-out-of-direction
status: active
merge_policy:
created_at: 2026-08-26T08:19:15+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260826081729-say-when-the-loop-has-run-out-of-direction.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Say when the loop has run out of direction

## Goal

Every mission so far enriched the loop's **turn**, not a direction's own life, so
three states are silent: a direction past its date (refused, while `pace` reads
`on_course`), a live direction nothing answers (`no_evolutionary_move`, into a report
nobody opens), and a repository with no live direction (`no_strategies`, a no-op
everywhere). Each is byte-identical to a healthy idle hour.

## Experience

A developer whose direction has finished, expired, or was never replaced is told
once, by name, in the channel — instead of watching an hourly loop go quiet and
guessing whether it is healthy or out of fuel. Each question names the reading, the
slug and the operator's next act, under the tick's existing holds and re-ask rule.
The loop asks; it never closes, never edits a live strategy, adds no field, and
lifts no gate.

## Acceptance

- [ ] `direction-state.sh` answers `live | overdue | dormant | unreadable`, plus the
      repository-level `none` (#20260826082029-write-direction-state-sh-the-one-lifecycle-reader.md)
- [ ] `direction-health` asks the assignee once per non-`live` reading and renders it
      on the root (#20260826082029-render-the-direction-reading-on-the-moderation-root.md)
- [ ] A test and a drill prove nothing was written and no gate lifted (#20260826082029-drill-direction-health-with-no-network.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
