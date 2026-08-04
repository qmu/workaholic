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
actual_hours:
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
feedback: [20260804173526-a-mission-is-created-with-two-or-more-tickets-or-it-is-not-a-mission.md]
---

# Make a mission impossible to create without its ticket set

## Goal

"Feedback", "ticket" and "mission" are only distinguishable if a mission has a lower
bound. Without one, a ticketless mission is a feedback record on the roadmap and a
one-ticket mission is a ticket with a progress bar — and both are produced today by
seams that mint a mission without emitting its tickets. Two of the eleven missions ever
created are in exactly those states, including one minted minutes before this mission.

## Experience

Every seam that brings a mission into existence emits at least two tickets in the same
pass, or refuses and says what to write instead — a feedback record for a bare
direction, a plain ticket for a single unit of work.

The refusal names the alternative rather than only the rule, because the author is not
wrong to have something to record; they are recording it as the wrong kind of thing.

The floor is checked where the mission and its tickets are published together, not at
the write of `mission.md` alone: the tickets legitimately do not exist yet when the file
is first written, so a write-time hook would refuse the normal authoring order.

## Acceptance

- [ ] The rule's boundary is decided and recorded — what counts toward the floor, and what a carry does now that a bare successor is forbidden (#20260804173624-decide-the-mission-ticket-floor-and-what-a-carry-does.md)
- [ ] Every creation seam enforces it, including the carried-close successor that produced the live violation (#20260804173625-enforce-the-mission-ticket-floor-at-every-creation-seam.md)
- [ ] The two existing sub-floor missions are resolved, and the docs describing mission creation say what the code does (#20260804173626-resolve-the-two-sub-floor-missions-and-align-the-docs.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
