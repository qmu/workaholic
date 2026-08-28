---
type: Mission
title: Deliver what the loop already knows to the person who can act
slug: deliver-what-the-loop-already-knows-to-the-person-who-can-act
status: active
merge_policy:
created_at: 2026-08-28T18:19:13+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260828181639-deliver-what-the-loop-already-knows-to-the-person-who-can-act.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260828-184133
---

# Deliver what the loop already knows to the person who can act

## Goal

The loop's one path from a machine finding to a person is jammed. `ask-question.sh` names
its all-time count `asked_today`, so every question is refused `day_cap` once the total
crosses it; the held backlog has no order; and a check-in that delivered nothing reports
`ok` and posts nothing, reading like a quiet hour.

## Experience

The developer is asked, in the `🔎 Moderation` thread, about what the loop has been holding
— oldest first — and the arrears clear over several ticks rather than in one wall. A tick
that reached nobody says so instead of looking quiet, and a reader can tell a cap spent
today from a mechanism that has stopped.

## Acceptance

- [ ] A question is refused `day_cap` only for that many asked on the current
      `WORKAHOLIC_QUIET_TZ` day; every other gate is byte-identical. (#20260828182002-bound-the-day-count-to-the-quiet-hours-day.md)
- [ ] A multi-day backlog drains oldest-held first under `max_per_tick`, and the drill
      proves it end to end with no network. (#20260828182002-drain-a-held-backlog-oldest-first.md)
- [ ] A check-in with candidates and zero delivered supplies its own `event` and names what
      it held and why, with a spent cap distinguished by name from a count it could not
      bound. (#20260828182002-make-a-tick-that-reached-nobody-an-event.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
