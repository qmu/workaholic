---
type: Mission
title: Resolve a conflicted pull request in the tick, not report it
slug: resolve-a-conflicted-pull-request-in-the-tick-not-report-it
status: achieved
merge_policy:
created_at: 2026-09-02T04:26:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 2.2
feedback: [20260902042549-the-moderation-tick-resolves-and-merges-it-does-not-report-stuckness.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260902-093741
---

# Resolve a conflicted pull request in the tick, not report it

## Goal

The operator states the implementation is entirely contrary to intent. The tick posts that
a conflict "belongs to the claim holder", and that a pull request cannot merge because
GitHub has not computed mergeability — then parks them. A claim holder never comes: parked
pull requests read as progress to the loop and as stagnation to its operator.

The tick's role is to decide, resolve and advance. This moves the conflict work from
reporting to acting, and retires the surfaces that stood in for it.

## Experience

The tick brings every conflicted pull request it can into a mergeable state itself and
merges it, and says what it did. One whose mergeability GitHub has not computed drops out
of the pass silently. Nothing is parked for a claim holder.

## Acceptance

- [x] A conflicted pull request the tick can settle is settled and merged by it, content
      conflicts included. (#20260902042630-let-the-tick-resolve-a-content-conflict-not-defer-it.md)
- [x] An uncomputed mergeable state drops the pull request from the pass and notifies
      nobody. (#20260902042630-drop-the-notification-for-an-uncomputed-mergeable-state.md)
- [x] No step and no prose defers a conflict to a claim holder or reports stuckness in
      place of resolving it. (#20260902042630-retire-the-surfaces-that-defer-a-conflict-to-a-claim-holder.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-02 — ticket archived — 20260902042630-localize-which-step-posted-each-of-the-three-corrected-lines.md
- 2026-09-02 — ticket archived — 20260902042630-let-the-tick-resolve-a-content-conflict-not-defer-it.md
- 2026-09-02 — ticket archived — 20260902042630-let-the-tick-merge-what-it-resolved.md
- 2026-09-02 — ticket archived — 20260902042630-drop-the-notification-for-an-uncomputed-mergeable-state.md
- 2026-09-02 — run recorded (+2.2h) — work-20260902-093741
- 2026-09-02 — ticket archived — 20260902042630-retire-the-surfaces-that-defer-a-conflict-to-a-claim-holder.md
- 2026-09-02 — mission achieved — mission.md
