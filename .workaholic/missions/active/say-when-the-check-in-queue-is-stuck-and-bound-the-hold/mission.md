---
type: Mission
title: Say when the check-in queue is stuck, and bound the hold
slug: say-when-the-check-in-queue-is-stuck-and-bound-the-hold
status: active
merge_policy:
created_at: 2026-08-31T11:24:17+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260831111927-human-checkin-holds-every-question-and-delivers-none.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260831-134347
---

# Say when the check-in queue is stuck, and bound the hold

## Goal

The check-in supplies an `event` only for `cap_spent` and `cap_unbounded`, because quiet
hours and an off day are the designed hold. That holds for one tick and fails across
days: measured, 24 consecutive ticks logged `0 delivered, 13 held (all_held)` while the
roots read `1 question(s)`. The step that exists to reach a human is the one whose
failure that human cannot see.

## Scope

`step-human-checkin.sh`'s own reading, the moderate wording, one drill. Not the keys,
the caps, the holds, `ask-question.sh`, or the diff rule.

## Experience

An operator learns questions are stacking up before the queue is days deep: an all-held
tick that outlived the designed hold says how many wait and how long the oldest has,
once, and each held question carries the word holding it. A hold inside the window is
unchanged.

## Acceptance

- [ ] An all-held tick whose arrears outlived the designed hold names their depth and age
      on the root, once, and an unchanged reading never restates. (#20260831112534-let-an-outlived-hold-earn-a-root-line.md)
- [ ] Every held question carries its own refusal word, so the reason is per question
      rather than aggregated into one token. (#20260831112534-say-why-each-held-question-is-held.md)
- [ ] Proved offline by a drill with a breaker row, in the register. (#20260831112535-drill-the-arrears-reading-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
