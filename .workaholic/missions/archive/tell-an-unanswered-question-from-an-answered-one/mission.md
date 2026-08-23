---
type: Mission
title: Tell an unanswered question from an answered one
slug: tell-an-unanswered-question-from-an-answered-one
status: achieved
merge_policy:
created_at: 2026-08-22T15:52:20+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260822155142-a-blocking-check-in-question-is-asked-once-and-then-never-again.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260823-141725
---

# Tell an unanswered question from an answered one

## Goal

`/moderate`'s check-in asked one question whose own body said the loop could not start until
it was answered. It was asked once. Twenty hours and roughly twenty ticks later it is still
unanswered and has never been mentioned again — every tick reporting itself healthy.

Nothing is broken by the letter of the design: ticket `20260819061902` fixed the gate to match
on the step id and stop re-asking. But that moved the failure rather than removing it, and the
two are not symmetric — an over-asked question is self-correcting, an unanswered one loses what
it was protecting, silently and without bound. The gate reads only whether a question was
asked, never whether it was answered or whether its subject is still live.

## Experience

An unanswered question is distinguishable from an answered one. A blocker that persists cannot
go a day without a surface saying so, and an ordinary question is still asked once.

## Acceptance

- [x] The gate can tell a question whose subject is still live from one that is settled (#20260822155250-read-whether-an-asked-question-s-subject-is-still-live.md)
- [x] An outstanding question is visible on a surface a person reads, with its age (#20260822155250-surface-the-outstanding-questions-and-their-age.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-23 — ticket archived — 20260822155250-read-whether-an-asked-question-s-subject-is-still-live.md
- 2026-08-23 — ticket archived — 20260822155250-surface-the-outstanding-questions-and-their-age.md
- 2026-08-23 — mission achieved — mission.md
