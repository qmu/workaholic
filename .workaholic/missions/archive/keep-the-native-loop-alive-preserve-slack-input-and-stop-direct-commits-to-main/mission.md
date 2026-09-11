---
type: Mission
title: Keep the native loop alive, preserve Slack input, and stop direct commits to main
slug: keep-the-native-loop-alive-preserve-slack-input-and-stop-direct-commits-to-main
status: achieved
merge_policy:
created_at: 2026-09-11T18:03:33+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260911180039-keep-the-native-loop-alive-preserve-slack-input-and-stop-direct-commits-to-main.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260911-181606
---

# Keep the native loop alive, preserve Slack input, and stop direct commits to main

## Goal

Issue #1151: a native session said it had returned to the loop and ended its turn with the
record still `running`; an unproved Slack read was called quiet while a human root sat unread;
and the tick's bookkeeping lands on `main` as direct commits.

## Experience

A mid-loop comment ends no turn until an interruptible parent or a same-chat scheduled
continuation is proved; `running` alone is never reported as resumed. An unproved or
unreadable observation is never quiet, never advances the cursor, retries on its own, and the
next read overlaps the unproved interval. No unattended path commits or pushes to `main`;
durable artifacts travel on a branch behind a pull request.

## Acceptance

- [x] A routine interruption returns to a proved continuation, and a `running` state without one is reported as not resumed (#20260911180401-prove-a-continuation-before-a-mid-loop-turn-ends.md)
- [x] A human root posted during an unproved observation is captured on the next read without a pasted permalink, and no unproved read advances the cursor (#20260911180402-treat-an-unproved-slack-observation-as-unread-not-quiet.md)
- [x] A base-ref write gate refuses direct commits and pushes to `main` from the Propose, Moderate, notification and finish-log paths, pinned by tests (#20260911180404-gate-every-unattended-write-to-the-base-ref-and-pin-it.md)

## Changelog
- 2026-09-11 — ticket archived — 20260911180401-prove-a-continuation-before-a-mid-loop-turn-ends.md
- 2026-09-11 — ticket archived — 20260911180402-treat-an-unproved-slack-observation-as-unread-not-quiet.md
- 2026-09-11 — ticket archived — 20260911180403-route-the-tick-s-durable-records-through-a-pull-request.md
- 2026-09-11 — ticket archived — 20260911180404-gate-every-unattended-write-to-the-base-ref-and-pin-it.md
- 2026-09-11 — mission achieved — mission.md
