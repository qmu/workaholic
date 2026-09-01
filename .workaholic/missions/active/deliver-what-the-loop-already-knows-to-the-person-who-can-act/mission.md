---
type: Mission
title: Deliver what the loop already knows to the person who can act
slug: deliver-what-the-loop-already-knows-to-the-person-who-can-act
status: active
merge_policy:
created_at: 2026-08-28T12:20:17+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260828121729-deliver-what-the-loop-already-knows-to-the-person-who-can-act.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260901-064758
---

# Deliver what the loop already knows to the person who can act

## Goal

`ask-question.sh` names a value `asked_today` and derives it from an unbounded
`log-read.sh` walk, so the day cap counts every question ever asked. It crossed
`max_per_day` on 2026-08-27 and the log never prunes, so every question is now
refused `day_cap` forever. Seven question-producing steps compute correctly into
that gate and reach nobody, while the step reports `ok`.

## Experience

The developer is asked, in the `🔎 Moderation` thread, about what the loop has
been holding — oldest first — and the arrears clear over several ticks rather
than in one wall. A tick that could reach nobody says so in the channel instead
of looking like a quiet hour.

## Acceptance

- [x] The day count is bounded to one derived day; a log carrying only earlier
      days' asks no longer refuses `day_cap`, pinned by a hermetic test. (#20260828122110-bound-the-check-in-day-count-to-one-derived-day.md)
- [x] Held findings are offered oldest-held first under the unchanged
      `max_per_tick`, so a multi-day backlog drains in urgency order. (#20260828122110-drain-a-multi-day-question-backlog-oldest-held-first.md)
- [ ] A check-in with candidates and zero delivered supplies its own `event` and
      names what it held, so total silence is a reported state, not `ok`. (#20260828122110-make-a-tick-that-reached-nobody-a-visible-event.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-01 — ticket archived — 20260828122109-reproduce-the-check-in-day-cap-jam-and-pin-it.md
- 2026-09-01 — ticket archived — 20260828122110-bound-the-check-in-day-count-to-one-derived-day.md
- 2026-09-01 — ticket archived — 20260828122110-drain-a-multi-day-question-backlog-oldest-held-first.md
