---
type: Mission
title: Read the base's colour past a bookkeeping tip
slug: read-the-base-s-colour-past-a-bookkeeping-tip
status: achieved
merge_policy:
created_at: 2026-08-31T20:29:23+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260831202854-base-health-never-reads-a-base-whose-tip-is-a-bookkeeping-commit.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260902-200652
---

# Read the base's colour past a bookkeeping tip

## Goal

`base-health` reported `base_unreadable:tip_no_checks` every tick for a day while the base
was green throughout. The loop's bookkeeping commits are excluded from every workflow's path
filter — correctly — so the tip is usually a commit nothing ran on, and
`attribute-base-red.sh` returns on an unanswerable tip before its walk begins. One word does
two jobs: `no_checks` is a fact about the commit with a defined answer one step back, while
`reader_failed` is a fact about us. Collapsed, they make the reading unreachable exactly
where the loop is busiest.

## Experience

A base whose tip nothing ran on still gets a colour every tick — the newest checked
ancestor's, with how far back it was — while a reading the loop could not make for its own
reasons stays terminal, named, and never walked past.

## Acceptance

- [x] A `no_checks` tip continues into the existing walk under its existing bound and reports
      the newest checked ancestor's colour. (#20260831202933-continue-the-base-walk-past-a-commit-nothing-ran-on.md)
- [x] Every other unanswerable reason stays terminal, and the distance is stated wherever the
      colour is read. (#20260831202934-say-how-far-back-the-base-s-colour-was-read.md)
- [x] A drill proves both offline and fails if a bookkeeping tip silences the reading again. (#20260831202934-drill-the-base-reading-past-a-bookkeeping-tip.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-02 — ticket archived — 20260831202933-continue-the-base-walk-past-a-commit-nothing-ran-on.md
- 2026-09-02 — ticket archived — 20260831202934-say-how-far-back-the-base-s-colour-was-read.md
- 2026-09-02 — ticket archived — 20260831202934-drill-the-base-reading-past-a-bookkeeping-tip.md
- 2026-09-02 — mission achieved — mission.md
