---
type: Mission
title: Settle a mergeability reading before it becomes a question
slug: settle-a-mergeability-reading-before-it-becomes-a-question
status: active
merge_policy:
created_at: 2026-09-01T08:25:31+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260901081927-moderation-reports-unknown-mergeability-and-defers-a-conflict-it-could-clear-itself.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260901-094857
---

# Settle a mergeability reading before it becomes a question

## Goal

An operator measured the tick reporting four pull requests as `unknown` and never
resolving them, and reporting a conflict on the loop's own generated index as somebody's
work. Diagnosis found the reporter's first two repairs already shipped: what is left is
that the **first** per-pull read is what schedules GitHub's lazy computation, so a `null`
becomes a finding instead of a second look — and that the tick's own wording sends a
person after a repair the loop performs itself.

## Experience

A pull request GitHub had not computed yet is looked at again before the tick reports it,
so `unknown` names only what stayed unknown. A conflict the loop clears itself says so,
while a content conflict still names its holder. The union attribute's shipped record says
on its face that GitHub applies none of it.

## Acceptance

- [x] An uncomputed mergeability is re-read once before it reaches a finding or a question (#20260901082631-re-read-an-uncomputed-mergeability-before-reporting-it.md)
- [ ] A conflicted pull request's reported decision distinguishes the loop's own repair from its holder's (#20260901082633-name-the-loop-s-own-repair-on-a-conflicted-pull-request.md)
- [ ] The shipped `merge=union` record states that GitHub applies no merge driver (#20260901082635-state-that-github-applies-no-merge-driver.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-01 — ticket archived — 20260901082631-re-read-an-uncomputed-mergeability-before-reporting-it.md
