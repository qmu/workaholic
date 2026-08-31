---
type: Mission
title: Notice a periodic artifact that stopped being produced
slug: notice-a-periodic-artifact-that-stopped-being-produced
status: achieved
merge_policy:
created_at: 2026-08-31T11:30:53+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260831113036-no-step-notices-a-periodic-artifact-that-stopped-being-produced.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260831-125156
---

# Notice a periodic artifact that stopped being produced

## Goal

Every one of the tick's steps is driven by an object that exists — an open pull request,
a commit, a ticket, a record. A routine that dies produces nothing, so no step has
anything to find: measured, a daily record stopped for four days while hourly ticks ran
throughout and none reported it. The tick watches presence and cannot watch absence.

## Scope

One declaration, one reader, one `/moderate` step, its wording, one drill. Not the
existing steps, the keys, the caps or the holds.

## Experience

A repository declares what it expects to be produced and how often, and is asked exactly
once when the newest one is older than that allows. A repository that declares nothing
behaves exactly as it does today, and a read we could not make is named rather than
reported as a lapse.

## Acceptance

- [x] A declared cadence whose newest artifact is older than its period asks its person
      exactly once; a current one asks nobody. (#20260831113118-ask-once-when-a-declared-cadence-has-lapsed.md)
- [x] A repository declaring no cadence is byte-identical to today, and an unreadable
      read is named with null counts rather than rendered as lapsed. (#20260831113118-read-whether-a-declared-cadence-is-current.md)
- [x] Proved offline by a drill with a breaker row, in the register. (#20260831113119-drill-the-cadence-reading-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-31 — ticket archived — 20260831113118-state-where-a-cadence-is-declared-and-what-it-says.md
- 2026-08-31 — ticket archived — 20260831113118-read-whether-a-declared-cadence-is-current.md
- 2026-08-31 — ticket archived — 20260831113118-ask-once-when-a-declared-cadence-has-lapsed.md
- 2026-08-31 — ticket archived — 20260831113119-drill-the-cadence-reading-offline.md
- 2026-08-31 — ticket archived — 20260831113118-state-the-cadence-reading-where-the-tick-is-defined.md
- 2026-08-31 — mission achieved — mission.md
- 2026-08-31 — story reported — work-20260831-125156.md
