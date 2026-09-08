---
type: Mission
title: Clear the residue the base already holds, and never stop silently
slug: clear-the-residue-the-base-already-holds-and-never-stop-silently
status: active
merge_policy:
created_at: 2026-09-08T17:56:28+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260908175556-clear-the-residue-the-base-already-holds-instead-of-stalling-the-loop-forever.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260908-192225
---

# Clear the residue the base already holds, and never stop silently

## Goal

Stop the loop stalling forever on residue the tree can prove the base already holds, and stop a
pre-survey termination reaching nobody. `sync-main.sh` keeps every property it protects; a layer
above it clears only what a `superseded`-shaped proof covers.

## Experience

A tick that finds the checkout dirty with content the base already holds, or with generated files
the repository's own generator rewrites, clears exactly that residue, freshens and reaches its
survey in the same tick. Anything it cannot prove is left untouched and named. A run that stops
before the survey reaches the channel.

## Acceptance

<!-- PROPOSED criteria, THREE ITEMS OR FEWER - a sketch for discussion, not a
     plan. Approval replans this mission to drive-ready; only then may it be
     authorized. -->

- [ ] One reader classifies every dirty path by proof, and never calls an unanswerable path clearable. (#20260908175714-classify-checkout-residue-by-proof-never-by-guess.md)
- [ ] The tick clears only proved residue, re-derives the proof at the act, and reaches its survey. (#20260908175714-clear-only-the-proved-residue-then-let-the-freshen-run.md)
- [ ] A run that stops before the survey posts its own signature, whatever the stop was. (#20260908175714-post-any-pre-survey-stop-not-only-the-listed-one.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
