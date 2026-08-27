---
type: Mission
title: Say when a direction has arrived
slug: say-when-a-direction-has-arrived
status: active
merge_policy:
created_at: 2026-08-27T14:22:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260827142027-say-when-a-direction-has-arrived.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260827-144111
---

# Say when a direction has arrived

## Goal

Every direction-layer reading answers *is this direction in trouble* — `pace`, `overdue`,
`dormant`, `unreadable`. None answers *has it arrived*, so a direction whose work is all in looks
like one still running, and when its date passes the loop reports that success as an hourly
`direction-overdue` question. This strategy's date is 2026-08-31.

## Scope

`quiescent` on every survey row; `arrived` in `direction-state.sh`; `step-direction-health.sh`
asking once. Nothing closes a direction; `quiescent` lifts no gate.

## Experience

The operator is told, once, in the channel, when a live direction of theirs has produced its work
and has nothing left in flight — with what landed and its date named — and answers by closing it
or saying it is not done. An arrived direction is never reported as overdue, one that merely ran
dry is still dormant, and nothing closes a direction on its own reading.

## Acceptance

- [ ] `quiescent` on every row, projected as `arrived` at `unreadable > arrived > overdue >
      dormant > live`, every gate and the sort unchanged. (#20260827142444-add-the-quiescent-reading-to-the-strategy-survey.md)
- [ ] An arrived direction reaches its assignee once, as a description of the reading. (#20260827142444-ask-the-operator-once-whether-an-arrived-direction-is-done.md)
- [ ] No reading closes a direction, pinned by a test. (#20260827142444-pin-that-no-reading-ever-closes-a-direction.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
