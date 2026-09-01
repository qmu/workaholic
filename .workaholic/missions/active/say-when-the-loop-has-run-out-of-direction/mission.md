---
type: Mission
title: Say when the loop has run out of direction
slug: say-when-the-loop-has-run-out-of-direction
status: active
merge_policy:
created_at: 2026-08-26T07:19:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260826071745-say-when-the-loop-has-run-out-of-direction.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260901-065202
---

# Say when the loop has run out of direction

## Goal

Everything landed here so far is about the **turn**. Three states of a direction's own life
are silent: past its date (refused, while `pace` reads `on_course`), live and unanswered
(into a report nobody opens), and no live direction at all (`no_strategies`, a no-op
everywhere). Each becomes a named reading and a question addressed to a person.

## Experience

A developer whose direction has finished, expired, or was never replaced is told once, by
name, in the channel — instead of watching an hourly loop go quiet and guessing whether it
is healthy or out of fuel. Each question names the reading, the slug and the operator's own
next act. Nothing closes a strategy, nothing edits a live one, no artifact gains a field,
and `/propose`'s gates are unchanged.

## Acceptance

<!-- PROPOSED - a sketch the reviewer replans drive-ready. -->

- [x] `overdue`, `dormant` and a repository-level `none` are readings composed from
      `survey-strategies.sh`; `unreadable` never collapses into them (#20260826110016-add-the-overdue-reading-to-the-strategy-survey.md)
- [ ] `/moderate`'s `direction-health` asks each non-`live` reading's assignee
      once and renders its event (#20260826110016-add-the-moderate-step-direction-health.md)
- [ ] A test and a drill prove the step writes nothing under `strategies/`,
      never closes and never lifts a gate (#20260826110016-pin-the-three-refusals-with-a-hermetic-test.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-01 — ticket archived — 20260826110016-add-the-overdue-reading-to-the-strategy-survey.md
- 2026-09-01 — ticket archived — 20260826110016-add-the-dormant-reading-to-the-strategy-survey.md
