---
type: Mission
title: Take the moderation tick's log off main
slug: take-the-moderation-tick-s-log-off-main
status: active
merge_policy:
created_at: 2026-08-31T18:20:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260831181658-take-the-moderation-tick-s-log-off-main.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260902-212324
---

# Take the moderation tick's log off main

## Goal

`main` is the development target's history and the loop is the largest author of
noise in it. Measured over one day on a consuming repository: 275 commits, 138
`.workaholic/`-only, 5 product-only — the largest author being the `/moderate`
tick log, a direct commit made three times a tick.

The log's content is load-bearing: the tick's only memory across discarded
containers. Its **home** is what is wrong. The operator ruled the direction — a
dedicated ref in this same repository, so no server appears.

## Experience

`main`'s history reads as units of product change: no commit on it writes
`.workaholic/moderations/`. A tick in a fresh container still reads every earlier
tick's log, concurrent ticks still union by `(tick, step)`, and a regression that
puts a tick log back on `main` fails a drill.

## Acceptance

- [ ] The tick log's home is a dedicated ref this repository creates and a fresh
      container fetches, and `main` carries no tick-log write. (#20260831182058-publish-the-tick-log-to-its-own-ref.md)
- [ ] Every reader reaches the log through one reader, concurrent ticks still
      union by `(tick, step)`, and the persist count per tick is justified by name. (#20260831182058-justify-or-drop-each-persist-the-tick-makes.md)
- [x] Two drills: one fails when a tick's log misses the ref, one fails when a
      tick log reaches `main` again. (#20260831182058-drill-that-a-tick-log-never-reaches-main.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-02 — ticket archived — 20260831182058-drill-that-a-tick-s-log-reaches-its-ref.md
- 2026-09-02 — ticket archived — 20260831182058-drill-that-a-tick-log-never-reaches-main.md
- 2026-09-02 — ticket archived — 20260831182058-rule-which-ref-the-tick-log-lives-on.md
