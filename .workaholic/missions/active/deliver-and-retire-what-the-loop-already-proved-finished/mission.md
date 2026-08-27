---
type: Mission
title: Deliver and retire what the loop already proved finished
slug: deliver-and-retire-what-the-loop-already-proved-finished
status: active
merge_policy:
created_at: 2026-08-27T05:22:01+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260827052027-deliver-and-retire-what-the-loop-already-proved-finished.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260827-054123
---

# Deliver and retire what the loop already proved finished

## Goal

Act on the two claim verdicts that are **proofs**, instead of reporting them to a
person and stopping. `report_undelivered` means the loop finished a unit and the
transport refused its merge, and no later run retries. `superseded` means the claim's
content already reached the base, and nothing retires the claim. Both stop at a report.

## Experience

An hourly run that finishes a unit **delivers** it: when the merge is refused, a later
run re-attempts it through the same seam and reports the outcome by name, so a green
pull request the loop opened stops waiting for a human to notice it. And the claim table
holds only live work — a claim the oracle proves finished has its pull request closed,
its branch deleted and its worktree reaped by the tick that proved it, so what a person
is asked about is only ever a reading that needed their judgement.

## Acceptance

- [x] Proofs and judgements are named once and read by every consumer (#20260827052237-name-which-claim-verdicts-are-proofs-and-which-are-judgements.md)
- [x] A later run re-attempts an undelivered unit's merge and reports the outcome (#20260827052237-re-attempt-an-undelivered-unit-s-merge-in-a-later-driving-run.md)
- [x] A claim proved `superseded` is retired by one writer after re-proof (#20260827052237-write-retire-claim-sh-the-one-retirement-writer.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-27 — ticket archived — 20260827052237-name-which-claim-verdicts-are-proofs-and-which-are-judgements.md
- 2026-08-27 — ticket archived — 20260827052237-re-attempt-an-undelivered-unit-s-merge-in-a-later-driving-run.md
- 2026-08-27 — ticket archived — 20260827052237-report-the-retry-s-outcome-and-move-the-token-only-when-it-delivered.md
- 2026-08-27 — ticket archived — 20260827052237-write-retire-claim-sh-the-one-retirement-writer.md
- 2026-08-27 — ticket archived — 20260827052241-add-the-moderate-step-that-retires-a-proved-claim.md
- 2026-08-27 — ticket archived — 20260827052241-drill-both-acts-with-no-network.md
- 2026-08-27 — ticket archived — 20260827052241-pin-the-proof-judgement-split-with-a-hermetic-test.md
