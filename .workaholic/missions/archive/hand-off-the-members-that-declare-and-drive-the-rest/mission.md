---
type: Mission
title: Hand off the members that declare, and drive the rest
slug: hand-off-the-members-that-declare-and-drive-the-rest
status: achieved
merge_policy:
created_at: 2026-09-07T02:37:55+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260907023405-drive-a-unit-s-non-declaring-members-instead-of-parking-seven-tickets-behind-one-honest-handoff.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260907-024858
---

# Hand off the members that declare, and drive the rest

## Goal

The handoff route is whole-unit: *any member declaring it carries the whole unit*. Measured
2026-09-06 on `report-each-tick-in-the-originating-codex-chat`: 7 queued tickets, one
declaring a prose handoff only the operator's own Codex chat can discharge, six declaring
nothing. The claim reads `awaiting_verification`, the survey excludes it, and the repository
drives nothing for hours.

## Experience

A unit whose members' declarations are mixed drives the members that declare nothing and hands
off only those that do. The split is a file test on the declaration, never a judgement about
what a ticket probably needs. Every refusal stands: a `probe:` still runs at claim time, prose
is still verified here first, a run still never declares one for its own unit, and an
all-declaring unit still hands off whole.

## Acceptance

- [x] A claim only partly declared is offered, not parked. (#20260907023855-offer-a-claim-whose-members-only-partly-declare.md)
- [x] One run drives the non-declaring members to a pull request and hands off only the
      declaring ones. (#20260907023855-drive-the-non-declaring-members-and-hand-off-the-rest.md)
- [x] Every consumer that assumed a whole-unit handoff reads the partial form. (#20260907023855-read-the-partial-handoff-at-every-consumer-that-assumed-the-unit.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-07 — ticket archived — 20260907023855-offer-a-claim-whose-members-only-partly-declare.md
- 2026-09-07 — ticket archived — 20260907023855-drive-the-non-declaring-members-and-hand-off-the-rest.md
- 2026-09-07 — ticket archived — 20260907023855-read-the-partial-handoff-at-every-consumer-that-assumed-the-unit.md
- 2026-09-07 — mission achieved — mission.md
