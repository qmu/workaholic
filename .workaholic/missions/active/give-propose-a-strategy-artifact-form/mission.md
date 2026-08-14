---
type: Mission
title: Give /propose a Strategy artifact form
slug: give-propose-a-strategy-artifact-form
status: active
merge_policy:
created_at: 2026-08-14T06:44:42+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260814064431-add-strategy-as-a-fourth-propose-artifact-type.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260814-074927
---

# Give /propose a Strategy artifact form

## Goal

`/propose` emits three forms — the record, a mission with its ticket set, one loose
ticket. The ask adds a fourth, **Strategy**, and wants a strategy's lifecycle
(created / changed / ended) announceable from Slack as an FB issue. Strategy was
revived 2026-08-13 as the operator's direction, explicitly operator-authored; this
mission is where that rule is widened or deliberately kept.

## Experience

A dated, owned direction that carries no executable plan comes out of `/propose` as a
strategy in the proposal PR — not a mission nobody can decompose, not record-only. An
announcement that a strategy was created, changed or ended lands on that strategy.

## Acceptance

<!-- PROPOSED sketch, not a plan — the reviewer replans this to drive-ready. -->

- [ ] `/propose`'s judgment names a fourth form and the written condition that selects it over a mission, a loose ticket, and record-only. (#20260814064513-add-the-strategy-form-to-propose-s-judgment-and-emit-path.md)
- [ ] A strategy-shaped ask published by `/propose` produces a valid `.workaholic/strategies/<slug>.md` (target_date, non-empty assignees, Aim, Schedule) inside the proposal PR. (#20260814064513-add-the-strategy-form-to-propose-s-judgment-and-emit-path.md)
- [ ] A strategy lifecycle announcement (created / changed / ended) is captured and lands on the named strategy instead of proposing unrelated work. (#20260814064513-capture-strategy-lifecycle-announcements-as-asks.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
