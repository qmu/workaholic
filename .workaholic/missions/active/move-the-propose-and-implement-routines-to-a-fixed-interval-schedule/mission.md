---
type: Mission
title: Move the Propose and Implement routines to a fixed-interval schedule
slug: move-the-propose-and-implement-routines-to-a-fixed-interval-schedule
status: active
merge_policy:
created_at: 2026-08-10T08:52:42+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [.workaholic/feedbacks/20260810085032-move-workaholify-proposal-and-implement-steps-to-a-fixed-interval-loop-instead-of-immediate-webhook-triggers.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260810-090432
---

# Move the Propose and Implement routines to a fixed-interval schedule

## Goal

Return the `[Propose]` and `[Implement]` routines to a fixed-interval loop
cadence (e.g. every 30 minutes, at :00/:30) instead of firing immediately on
a GitHub webhook event — the loop-engineering premise this repo was built on
— and give the developer a working way to provision that schedule, reviving
the `/set-routines` idea.

## Experience

A developer no longer wires `[Propose]`/`[Implement]` to a GitHub event in
the routines UI; each instead runs on its own fixed interval
(`cron_expression`), and a command walks the developer through provisioning
that schedule for a repository — the scheduled cadence, not instant
reaction, is what produces the loop's feedback.

## Acceptance

- [x] The `[Propose]` and `[Implement]` routine templates (and
      `render-setup-sheet.sh`'s derived UI steps) declare a fixed-interval
      schedule trigger instead of an immediate GitHub webhook trigger. (#20260810085347-declare-a-fixed-interval-cron-trigger-on-the-propose-and-implement-routine-templates.md)
- [ ] A revived `/set-routines`-equivalent command helps a developer
      provision that fixed-interval schedule for a repository's routines. (#20260810085351-revive-set-routines-to-provision-the-routines-fixed-interval-trigger.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-10 — ticket archived — 20260810085347-declare-a-fixed-interval-cron-trigger-on-the-propose-and-implement-routine-templates.md
