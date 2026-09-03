---
type: Mission
title: Make a red base impossible for the loop to miss
slug: make-a-red-base-impossible-for-the-loop-to-miss
status: active
merge_policy:
created_at: 2026-09-03T09:02:21+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260903090153-a-red-base-can-go-unseen-an-unrun-suite-reads-as-a-pass-and-a-detected-red-waits-for-morning.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260903-123219
---

# Make a red base impossible for the loop to miss

## Goal

The base was red for about an hour and nothing surfaced it, through two independent mechanisms.
A path-filtered workflow meant the broken suite never ran on the offending commit, and
`base-health` reads the newest verdict the base carries — so a missing verdict and a passing one
are indistinguishable and the base was green in every reading while the loop kept merging into
it. Separately, a red base that *was* caught correctly was announced as a `base-red:<sha>`
question and held by `quiet_hours` until morning, while the loop built on it all night.

## Experience

The loop cannot be unaware that its base is red. A suite that did not run on the tip is named as
unverified rather than folded into green, wherever the base colour is reported; and a red base
reaches the channel as a report under its own cool-down rather than waiting for a speaking window
it was never addressed to.

## Acceptance

- [ ] `base-health` requires a verdict per declared suite on the tip and answers `unverified: <suite>` for one with no run on that commit (#20260903090250-require-a-verdict-per-declared-suite-on-the-tip.md)
- [ ] Every surface reporting the base colour names an unverified suite, and never renders it as green (#20260903090250-name-an-unverified-suite-wherever-the-base-colour-is-reported.md)
- [ ] A red base is reported as `🔴 Blocked` under the existing failure-signature cool-down rather than held as a question by `quiet_hours` (#20260903090250-report-a-red-base-instead-of-asking-about-it.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
