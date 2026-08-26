---
type: Mission
title: Turn the loop at mission granularity
slug: turn-the-loop-at-mission-granularity
status: active
merge_policy:
created_at: 2026-08-26T02:23:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260826022235-tie-missions-to-strategies-and-let-propose-plan-them.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260826-031417
---

# Turn the loop at mission granularity

## Goal

The operator asks that the loop turn one **mission** at a time: `/propose` plans a new
mission for a strategy instead of one change, proposals stop converging on housekeeping by
being coarser, and a mission normally belongs to the strategy whose context produced it —
usual, not mandatory. Today `/propose` judges one evolutionary move and `/specificate`
re-derives the decomposition from prose, so the loop's unit of work is a change and the
strategy→mission link is a side effect of the carried `feedback:` refs rather than the
visible shape of the roadmap.

## Experience

A `[Propose]` tick opens an issue that names a mission — its title, the experience it
demands, and its ordered ticket set. The `[Specificate]` tick that ingests it emits that
mission, with the strategy's refs on it, rather than re-deciding the plan. The roadmap shows
which strategy a mission belongs to. `/propose` proposes against a strategy again only when
that strategy's mission is finished, so the loop turns one mission per strategy at a time.

## Acceptance

<!-- PROPOSED criteria, THREE ITEMS OR FEWER - a sketch for discussion, not a
     plan. Approval replans this mission to drive-ready; only then may it be
     authorized. -->

- [ ] `/propose` proposes a **mission**: the issue names a title, an experience and an
      ordered ticket set at the ruled 7–8 scale, and the housekeeping brakes hold at that grain (#20260826022347-judge-a-whole-mission-not-one-change.md)
- [ ] `/specificate` emits the mission the ask names rather than re-deriving it, and the
      strategy→mission link is visible on the roadmap with no field added to any artifact (#20260826022347-emit-the-mission-the-ask-already-planned.md)
- [ ] `/propose`'s brake bounds one mission in flight per strategy, and every affected
      document is updated in the same change (#20260826022347-bound-the-brake-to-one-mission-per-strategy.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
