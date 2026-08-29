---
type: Mission
title: Read back whether the loop's own act took effect
slug: read-back-whether-the-loop-s-own-act-took-effect
status: active
merge_policy:
created_at: 2026-08-29T15:20:59+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260829151654-read-back-whether-the-loop-s-own-act-took-effect.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260829-154131
---

# Read back whether the loop's own act took effect

## Goal

Every reading answers *what did I find*; none answers *did what I did happen*.
Measured 2026-08-29: `claim-retirement.yml` is green on every run while three
proved-`superseded` claims stand and `retire-blocked` fires for none, because
`ci-retirement-turn.sh` infers *taken* from a completed run at the tip; CI's log
shows `candidates: []` where the container's reader finds them.

## Experience

An act the loop takes is read back against the world before the next tick trusts
it. A turn that ran without taking the act is a named answer, not a success.
A claim still standing after a completed turn reaches its holder with the word
blocking it, and a *changed* word reaches them even when an earlier one did.
No new store, no field, no second oracle.

## Acceptance

- [x] A CI turn records per candidate what each act answered, and
      `ci-retirement-turn.sh` answers from it, never from a run's exit
      status. (#20260829152415-answer-the-ci-turn-from-the-recorded-verdict.md)
- [x] A changed refusal reaches the claim holder, an unchanged one stays held, and
      the effect is read once for Act 2 and the retry. (#20260829152419-answer-did-my-act-take-effect-in-one-place.md)
- [x] An offline drill fails when a green run stands in for an act not taken, and
      is registered so `verify-all` and CI run it. (#20260829152420-drill-the-silent-act-offline-and-register-the-drill.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-29 — ticket archived — 20260829152415-pin-the-silent-act-with-a-failing-offline-reproduction.md
- 2026-08-29 — ticket archived — 20260829152415-record-what-the-ci-turn-attempted-and-each-act-answered.md
- 2026-08-29 — ticket archived — 20260829152415-answer-the-ci-turn-from-the-recorded-verdict.md
- 2026-08-29 — ticket archived — 20260829152419-answer-did-my-act-take-effect-in-one-place.md
- 2026-08-29 — ticket archived — 20260829152415-let-a-changed-refusal-reach-the-claim-holder.md
- 2026-08-29 — ticket archived — 20260829152420-name-the-effect-reading-where-the-tick-and-the-run-speak.md
- 2026-08-29 — ticket archived — 20260829152420-drill-the-silent-act-offline-and-register-the-drill.md
