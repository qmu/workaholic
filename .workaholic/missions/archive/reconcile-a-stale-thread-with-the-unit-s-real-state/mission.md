---
type: Mission
title: Reconcile a stale thread with the unit's real state
slug: reconcile-a-stale-thread-with-the-unit-s-real-state
status: achieved
merge_policy:
created_at: 2026-08-28T06:22:21+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 2.4
feedback: [20260828061724-let-the-moderation-tick-reconcile-a-thread-s-last-status-with-the-unit-s-real-state.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260828-064059
---

# Reconcile a stale thread with the unit's real state

## Goal

A finish line is posted only by the run that finishes the unit, so when a person merges a
handed-off pull request by hand it is never posted: the thread keeps `🔵 Proposed` or
`🟡 Handoff` while the work is long merged. No step reads that gap — `stuck-prs` reads open
pull requests, `handoff-units` a standing claim.

## Experience

A thread never keeps `🔵 Proposed` or `🟡 Handoff` as its last word once the pull request it
names has merged or closed. The tick derives candidates from the repository, finds the item's
thread through the existing exact-token lookup, reads it before writing, and posts the missing
finish reply once — naming that it merged outside the loop, by whom and when. A thread already
carrying its finish is untouched. It merges nothing, claims nothing, posts nowhere else.

## Acceptance

- [x] One reader derives from the repository which announced items may still be called in flight (#20260828062308-read-which-announced-items-may-still-be-called-in-flight.md)
- [x] The tick posts the missing reply into the item's own thread once, never over a thread that carries its finish (#20260828062308-post-the-missing-finish-reply-exactly-once.md)
- [x] The shape is named once in the catalog and the [Moderate] template, and a drill proves the bounds (#20260828062308-drill-the-reconciliation-with-no-network.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-28 — ticket archived — 20260828062308-read-which-announced-items-may-still-be-called-in-flight.md
- 2026-08-28 — ticket archived — 20260828062308-name-the-reconciliation-reply-once-in-the-catalog.md
- 2026-08-28 — ticket archived — 20260828062308-add-the-thread-reconcile-step-to-the-tick.md
- 2026-08-28 — ticket archived — 20260828062308-post-the-missing-finish-reply-exactly-once.md
- 2026-08-28 — ticket archived — 20260828062308-drill-the-reconciliation-with-no-network.md
- 2026-08-28 — mission achieved — mission.md
- 2026-08-28 — story reported — work-20260828-064059
- 2026-08-28 — run recorded (+2.4h) — session_01R1bEeXNE17o2keLC5qXbso
