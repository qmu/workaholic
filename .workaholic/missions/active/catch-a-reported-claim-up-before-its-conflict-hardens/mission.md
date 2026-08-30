---
type: Mission
title: Catch a reported claim up before its conflict hardens
slug: catch-a-reported-claim-up-before-its-conflict-hardens
status: active
merge_policy:
created_at: 2026-08-30T04:26:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260830042547-catch-a-reported-claim-up-before-its-conflict-hardens.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260830-044152
---

# Catch a reported claim up before its conflict hardens

## Goal

One `mergeability` reading feeds two candidate sets that disagree. `/moderate`
**asks** about `content` on a `report_undelivered` **or** `queue_drained` claim;
`/implement` **acts** only on `report_undelivered`. A `queue_drained` claim is
therefore asked about once hardened and never acted on while still
machine-settleable — the loop waiting for its own finished work to become a
person's job. Live: one mechanical four days, another content for twelve.

## Experience

When a run finishes a unit whose pull request waits on a person, the loop keeps
that branch mergeable itself: the next tick seeing a **reported** claim of this
identity still **mechanical** merges the base in, regenerates, checks and pushes.
A `content` conflict is refused, branch byte-identical, and still reaches its
holder once. A reviewed pull request is left alone, by name.

## Acceptance

- [ ] A `queue_drained` claim of this identity still `mechanical` is caught up
      and pushed, once per unit (#20260830042803-take-the-act-on-every-catchable-claim-in-the-run.md)
- [ ] A reviewed pull request is refused by its own word, branch byte-identical;
      every existing refusal unchanged (#20260830042803-refuse-a-pull-request-a-person-has-already-reviewed.md)
- [x] When a bounded act may read a judgement is written once, consumers
      enumerated, suite failing on a fourth (#20260830042803-state-when-a-bounded-act-may-read-a-judgement.md)

## Changelog

- 2026-08-30 — issue #744
- 2026-08-30 — ticket archived — 20260830042803-state-when-a-bounded-act-may-read-a-judgement.md
