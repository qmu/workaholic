---
type: Mission
title: Make the tick's root earn its hour
slug: make-the-tick-s-root-earn-its-hour
status: active
merge_policy:
created_at: 2026-08-22T17:50:45+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260822175026-the-moderation-root-posts-every-hour-by-construction-and-says-nothing-actionable.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260822-200945
---

# Make the tick's root earn its hour

## Goal

The Moderation root posts every hour and carries nothing anybody can act on. Not a thin hour
— structural. A change is a raw string compare of a step's summary against the previous
tick's, and two steps embed a moving value in that summary (a timestamp, a sha), so both are
"changed" on every run forever. The property that made an hourly root admissible — a diff
cannot restate an unchanged answer — does not hold. The gates are OR, so a `0 question(s)`
tick posts anyway, and the lines report the tick's own counters rather than the project's
events.

## Experience

An hour in which nothing happened and nothing is being asked is silent. When the root does
post, every line names something that happened to the repository.

## Acceptance

- [x] An hour whose steps found the same thing as the hour before produces no change (#20260822175131-diff-the-tick-s-steps-on-a-stable-form.md)
- [x] A root with no question posts only for a named class of change, never for a differing
      summary string (#20260822175131-make-a-question-less-root-earn-its-post.md)
- [ ] Every rendered line names a repository event, not a tick counter (#20260822175131-say-what-happened-not-what-the-tick-counted.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-22 — ticket archived — 20260822175131-diff-the-tick-s-steps-on-a-stable-form.md
- 2026-08-22 — ticket archived — 20260822175131-make-a-question-less-root-earn-its-post.md
