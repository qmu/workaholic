---
type: Mission
title: Repair a mechanically resolvable conflict instead of reporting it
slug: repair-a-mechanically-resolvable-conflict-instead-of-reporting-it
status: active
merge_policy:
created_at: 2026-08-31T20:22:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260831201820-every-open-proposal-conflicts-on-the-generated-feedbacks-index.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Repair a mechanically resolvable conflict instead of reporting it

## Goal

Every open proposal on a consuming repository collided on the same generated index. The
repair was mechanical and total — merge the base, regenerate, commit — and the loop filed
tickets instead while the tick reported the blockage hourly. `conflict-class.sh` already
calls a flat area's index mechanical; what has no reader at all is a **publish-tree
publication**, which is never a claim, so no candidate set, no `mergeability` row and no
repair path ever sees it.

## Experience

A publication the loop opened and could not merge is brought back to mergeable by the loop
itself whenever a generator settles its conflict — and a person is told only about a
conflict that is genuinely theirs, named by the files it collided on.

## Acceptance

- [ ] A publication colliding only on a generated region is caught up and delivered with no
      person, and a re-run is a no-op. (#20260831202250-settle-a-stranded-publication-a-generator-can-repair.md)
- [ ] One colliding on content is refused by its own word, left byte-identical, and reaches
      its author once. (#20260831202250-ask-about-a-publication-only-a-person-can-settle.md)
- [ ] A drill proves both offline and fails if a settleable conflict is reported rather than
      repaired. (#20260831202250-drill-the-stranded-publication-repair-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
