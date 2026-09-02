---
type: Mission
title: Announce an ask that landed outside a unit route in its own thread
slug: announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread
status: active
merge_policy:
created_at: 2026-09-03T05:27:53+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260903052643-give-an-ask-that-landed-outside-implement-a-finish-line-in-its-own-thread.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260903-054004
---

# Announce an ask that landed outside a unit route in its own thread

## Goal

An ask swept off the channel gets its receipt in its own thread. When the work lands through a
session working it directly rather than an `/implement` unit, no unit reaches the route step
and no finish line is posted, so an ask that shipped hours ago and one nobody started look
identical. Measured 2026-09-02: three merged PRs, the issue closed, and the operator found out
by asking a session.

## Experience

An ask whose `[FB]` issue has closed carries one finish line in its own thread naming what
landed, however the work reached `main`. It is posted once and never repeated, an idle tick
posts nothing, and a reading the tick could not make leaves the thread alone.

## Acceptance

- [x] A closed `[FB]` issue whose thread carries a receipt and no finish line is named by a
      repository-derived reader that never scans the channel. (#20260903052915-name-the-closed-asks-whose-thread-carries-no-finish-line.md)
- [ ] The tick posts one finish line into that thread naming what landed and by whom, and
      posts nothing for an item already announced. (#20260903052915-post-the-finish-line-from-the-tick-once-per-ask.md)
- [ ] An idle tick and an unreadable read both leave the thread alone, and a drift in the
      post shape fails a check. (#20260903052915-hold-the-tick-silent-where-it-cannot-see.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-03 — ticket archived — 20260903052915-name-the-closed-asks-whose-thread-carries-no-finish-line.md
