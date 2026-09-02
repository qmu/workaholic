---
type: Mission
title: Stop a routine tick from parking on a permission prompt
slug: stop-a-routine-tick-from-parking-on-a-permission-prompt
status: active
merge_policy:
created_at: 2026-09-02T04:30:50+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260902043038-the-propose-tick-parks-on-a-permission-prompt-every-hour.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260902-043932
---

# Stop a routine tick from parking on a permission prompt

## Goal

`[Propose]` sits at `requires_action` hourly, on records recreated fresh on 2026-09-01, so
this is not stale wiring. The same class was measured on `[Moderate]`: three consecutive
ticks parked on a prompt raised by two reads. A parked tick spends its fire, produces
nothing, and reads as scheduled and healthy — and it blocks the one routine that
originates the loop's work.

An unattended routine that waits on a person is worse than one that fails. The repair is at
the source: nothing the run does may raise a prompt.

## Experience

An hourly tick either completes or fails with a reason. It never waits on a person. What
the run reaches for cannot raise a prompt, a run that parked is visible as parked rather
than as healthy, and a regression that reintroduces the raise fails a check.

## Acceptance

- [ ] What raises the prompt in the `/propose` path is named from evidence and removed at
      its source. (#20260902043117-remove-the-prompt-raising-read-at-its-source-in-the-propose-path.md)
- [ ] A tick that parked is visible as parked rather than as scheduled and healthy. (#20260902043117-make-a-parked-routine-tick-visible-as-parked.md)
- [ ] A regression that reintroduces a prompt-raising shape fails a check before it ships.

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
