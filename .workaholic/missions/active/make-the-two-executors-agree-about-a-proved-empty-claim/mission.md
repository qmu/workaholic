---
type: Mission
title: Make the two executors agree about a proved-empty claim
slug: make-the-two-executors-agree-about-a-proved-empty-claim
status: active
merge_policy:
created_at: 2026-08-29T19:30:39+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260829192941-three-proved-superseded-claim-branches-still-stand-after-ci-s-retirement-turn.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260829-205701
---

# Make the two executors agree about a proved-empty claim

## Goal

Three proved-`superseded` branches have stood on origin since 2026-08-21 while
`Claim Retirement` is green on every run. Measured 2026-08-29: the container's
`list-retirable-claims.sh` names all three; CI's own recorded reading is
`ok=true reason= count=0` — byte-identical to a healthy, empty turn.

## Scope

The legibility of CI's recorded reading, the repair that lets the act re-derive
`superseded` where CI runs, and the drill row that would have caught it.

## Acceptance

- [ ] A unit CI's turn never saw is named by its own reading, never `taken`, and reaches
      the person who can act. (#20260829193103-say-why-ci-s-turn-never-saw-a-unit-the-container-proves-empty.md)
- [ ] The two executors' candidate readers agree over the same refs, and the branches
      of the three named units are gone from origin. (#20260829193103-let-the-retirement-act-re-derive-superseded-where-ci-runs.md)
- [ ] No verdict word is added, the proof gate is not widened, and no branch behind a live
      or foreign claim is deletable. (#20260829193103-drill-the-two-executors-agreeing-with-no-configured-git-identity.md)

## Experience

`Claim Retirement` is green **and** the claim table shrinks, or the loop says by name
which unit CI could not see. A turn that found nothing and one that found three and could
act on none are never one reading.

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
