---
type: Mission
title: Close the units the loop already finished
slug: close-the-units-the-loop-already-finished
status: active
merge_policy:
created_at: 2026-08-27T01:18:41+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260827011638-close-the-units-the-loop-already-finished.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Close the units the loop already finished

## Goal

The loop drives work to a green pull request and stops: a routine container's REST merge is
answered `session_type_cannot_merge`, and the one permitted connector retry lives only in prose,
with nothing recording whether it was taken. The stopped unit then reads `claimed_reported`, like
one waiting on a person, and `/implement` reports `ok`.

Measured 2026-08-27: #622, #625, #633, #635 green and unmerged; 11 queued, 0 offered.

## Experience

An hour ends and the loop has finished four units, delivered none, offered none of its eleven
queued tickets, and left an `ok` in a report nobody opens.

After this, a unit the loop finishes reaches `main`, or the run names the refusal that stopped it,
in the run report and once to a person by name. A survey that offers nothing tells a human's
business from the loop's undelivered work, and `ok` stops covering the second.

## Acceptance

- [ ] A `review` unit's report names its merge outcome — `merged` or the `merge-reason.sh` word —
      and the connector retry's. (#20260827012032-give-a-unit-s-close-its-own-reported-outcome.md)
- [ ] `/implement` refuses `ok` over a unit it left undelivered, and still reports `ok` over one a
      scan finding holds. (#20260827012035-never-report-ok-over-an-undelivered-unit.md)
- [ ] `loop-drill.sh verify-close` proves all four closing outcomes with no network. (#20260827012039-drill-the-closing-seam-with-no-network.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
