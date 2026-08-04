---
type: Mission
title: Make a mission impossible to create without its ticket set
slug: make-a-mission-impossible-to-create-without-its-ticket-set
status: active
merge_policy: 
created_at: 2026-08-04T17:35:49+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 1.5
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
feedback: [20260804173526-a-mission-is-created-with-two-or-more-tickets-or-it-is-not-a-mission.md]
claim: work-20260804-084744
---

# Make a mission impossible to create without its ticket set

## Goal

"Feedback", "ticket" and "mission" are only distinguishable if a mission has a lower
bound. Without one, a ticketless mission is a feedback record on the roadmap and a
one-ticket mission is a ticket with a progress bar. Two of eleven missions ever created
are in those states, both minted by seams that create without emitting tickets.

## Experience

Every seam that creates a mission emits at least two tickets in the same pass, or
refuses and names what to write instead — a feedback record for a bare direction, a
plain ticket for a single unit of work. Naming the alternative is the point: the author
is not wrong to have something to record, only to record it as the wrong kind of thing.

The floor is checked where the mission and its tickets are published together, never at
the write of `mission.md` alone — the tickets do not exist yet then, so a write-time
hook would refuse the normal authoring order.

## Acceptance

- [x] The boundary is decided and recorded: what counts, and what a carry does now (#20260804173624-decide-the-mission-ticket-floor-and-what-a-carry-does.md)
- [x] All four creation seams enforce it, including the carried close (#20260804173625-enforce-the-mission-ticket-floor-at-every-creation-seam.md)
- [ ] The two sub-floor missions are resolved and every doc states the floor (#20260804173626-resolve-the-two-sub-floor-missions-and-align-the-docs.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
- 2026-08-04 — ticket archived — 20260804173624-decide-the-mission-ticket-floor-and-what-a-carry-does.md
- 2026-08-04 — run recorded (+0.5h) — 20260804-184949
- 2026-08-04 — ticket archived — 20260804184949-a-carry-into-an-existing-mission-silently-drops-the-remainder.md
- 2026-08-04 — run recorded (+1h) — 20260804-190000
- 2026-08-04 — ticket archived — 20260804173625-enforce-the-mission-ticket-floor-at-every-creation-seam.md
