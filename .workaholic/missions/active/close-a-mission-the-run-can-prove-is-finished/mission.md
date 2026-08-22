---
type: Mission
title: Close a mission the run can prove is finished
slug: close-a-mission-the-run-can-prove-is-finished
status: active
merge_policy:
created_at: 2026-08-22T18:22:55+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260822182237-nothing-closes-a-finished-mission-so-completion-accumulates-in-the-active-area.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Close a mission the run can prove is finished

## Goal

`missions/active/` held 21 missions; 11 had full acceptance and zero queued tickets and had been
finished for days. Every survey walked them and the mission lens listed all 11 as the session's
business, so two thirds of the roadmap a run is steered by was noise — and a twelfth, finished in
the same session, had to be reported as still claimable.

The run archives tickets, ticks acceptance, appends changelog lines, opens the PR and merges it,
and never ends the mission. That rule is sound where the outcome is a judgement. It also covers
the one case that is arithmetic — full acceptance, empty queue — which the run computed before it
finished.

## Experience

A mission the run can prove is finished is closed by the run, in the same report as the work.
One it cannot prove is left alone and named, so a person sees what is waiting rather than
finding it in a lens.

## Acceptance

- [ ] A mission whose last ticket is archived, whose acceptance is fully checked and whose queue
      is empty is closed `achieved` through `close.sh`, and the close is in the run report (#20260822182303-close-a-fully-accepted-mission-at-the-archive-gate.md)
- [ ] Missions at full acceptance the seam did not close are reported as a named set (#20260822182303-report-the-missions-waiting-to-be-closed.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
