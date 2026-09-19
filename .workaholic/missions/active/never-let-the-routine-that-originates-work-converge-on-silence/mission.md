---
type: Mission
title: Never let the routine that originates work converge on silence
slug: never-let-the-routine-that-originates-work-converge-on-silence
status: active
merge_policy:
created_at: 2026-09-19T09:36:51+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260919093448-propose-converges-on-silence-and-stops-feeding-implement.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Never let the routine that originates work converge on silence

## Goal

`/propose` ended 64 consecutive ticks with `{"proposed": 0}` while eight inbound items sat open
and nothing was queued — every gate correct. Three causes compound: `open_proposal` holds forever
when the next stage is dead, a zero-proposal tick reads as a healthy idle one, and an operator
priority belonging to no direction is unreachable.

## Experience

A tick that originates nothing says **why**, where a person reads it. A proposal the next stage
never ingested stops holding its direction once the tree proves so. An operator ask no direction
claims is named. No judgement is weakened.

## Acceptance

<!-- PROPOSED - a sketch the reviewer replans drive-ready. -->

- [ ] A run of ticks that all originate nothing raises one named finding where a person reads it (#20260919093809-raise-a-run-of-originate-nothing-propose-ticks-as-a-finding.md)
- [ ] `open_proposal` stops holding a direction once the tree proves the ingest stage has not run
      since the proposal opened — derived from a reading, never a new constant (#20260919093809-stop-open-proposal-holding-a-direction-when-the-ingest-stage-is-not-running.md)
- [ ] An operator ask no direction claims is named; no origination bypasses a strategy (#20260919093809-name-the-operator-ask-that-answers-no-direction.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
