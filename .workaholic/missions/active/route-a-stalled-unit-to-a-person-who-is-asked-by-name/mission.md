---
type: Mission
title: Route a stalled unit to a person who is asked by name
slug: route-a-stalled-unit-to-a-person-who-is-asked-by-name
status: active
merge_policy:
created_at: 2026-08-23T09:37:55+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260823093733-a-blocked-unit-s-escalation-reaches-nobody-and-the-moderator-never-learns-of-it.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260823-112419
---

# Route a stalled unit to a person who is asked by name

## Goal

A loop stopped for eleven consecutive ticks. Every tick ran, reported `blocked` correctly and
spent agent-hours; the only outbound signal was a mention-less reply inside a feedback thread
from the previous day. Slack notified nobody, channel level showed nothing, and the developer
found the stall by noticing the channel had not moved in ten hours.

There is no path from *the loop is stuck* to *a person is asked*. `/implement`'s blockers never
reach `/moderate`, whose check-in is the one surface that names a person; both alert shapes
carry no mention token by design; and the reply threads into an item rather than an alert. Every
individual mechanism behaved exactly as specified while that was true.

## Experience

A unit stopped long enough to matter becomes a moderator question that names its owner, so Slack
notifies them. They answer in the moderator's own session through the link the question carries,
and the next tick sees it answered rather than re-holding it.

## Acceptance

- [ ] The tick reads what is claimed and how long it has been stopped (#20260823093803-read-what-is-claimed-and-how-long-it-has-been-stopped.md)
- [ ] A long-stalled unit is asked about by name, through the check-in (#20260823093803-ask-the-owner-of-a-stalled-unit-by-name-through-the-tick.md)
- [ ] An answer given in the moderator session stops the question being re-held, and is
      distinguishable from never having been asked (#20260823093803-let-an-answer-in-the-moderator-session-clear-the-question.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
