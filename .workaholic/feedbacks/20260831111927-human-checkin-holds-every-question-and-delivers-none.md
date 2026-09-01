---
type: Feedback
title: human-checkin holds every question and delivers none
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-31T11:19:27+00:00
author: a@qmu.jp
supersedes: 
---

# human-checkin holds every question and delivers none

# human-checkin holds every question and delivers none, and nothing says the queue is stuck

Source: https://github.com/qmu/workaholic/issues/760

Measured on a consuming repository: 24 consecutive ticks logged

    `human-checkin`: 0 delivered, 13 held (all_held)

Thirteen questions had accumulated and not one was delivered. Over the same hours the
posts the operator actually saw read `0 change(s), 1 question(s)` and
`0 change(s), 3 question(s)`, so the visible number bears no relation to the thirteen
waiting behind it.

Nothing in the post, and nothing in the log line beyond the `all_held` token itself,
says the queue is stuck or that it is growing. There is no bound on the hold and no
escalation when everything is held. The step that exists to reach a human is the one
step whose failure is invisible to that human.

Please make an all-held tick say so where the operator reads, and bound the hold —
either an escalation after N ticks, or a stated reason per held question.
