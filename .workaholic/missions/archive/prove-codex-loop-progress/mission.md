---
type: Mission
title: Prove Codex loop progress
slug: prove-codex-loop-progress
status: achieved
merge_policy:
created_at: 2026-09-04T14:23:28+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260904142216-make-work-prove-transport-and-progress-instead-of-silently-looping.md, 20260904142833-relay-codex-loop-slack-notifications-through-the-connector-owning-main-thread.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260904-184903
---

# Prove Codex loop progress

## Goal

Make starting and observing the Codex form of `/work` prove that the loop can execute and report,
instead of equating a live supervisor process with useful progress.

## Experience

An operator starting `/work` sees the first tick's actual outcome, the Slack transport verdict,
what `/implement` and `/propose` did, and when another tick is due. Later ticks leave one durable,
queryable account of progress or the exact reason work did not move. A loop with no connected
report path fails visibly while the existing FB-thread-to-Implemented Slack journey remains intact.

## Acceptance

- [x] Starting the Codex loop executes and evaluates a first tick before reporting the loop ready. (#20260904142404-gate-codex-loop-startup-on-the-first-tick.md)
- [x] Every tick records its outcome, blocked reason, and next due time in one observable status. (#20260904142405-record-each-codex-tick-outcome-and-next-due-time.md)
- [x] Missing Slack/report transport is a visible readiness failure, while successful runs preserve FB and Implemented threading. (#20260904142405-expose-codex-loop-status-to-the-invoking-session.md)

## Changelog

- 2026-09-04: Proposed from issue #974 after reproducing the supervisor/process-versus-progress gap.
- 2026-09-04: Extended from issue #975 with a connector-owning parent relay plan.
- 2026-09-04 — ticket archived — 20260904142404-reproduce-and-classify-codex-loop-readiness-failures.md
- 2026-09-04 — ticket archived — 20260904142404-gate-codex-loop-startup-on-the-first-tick.md
- 2026-09-04 — ticket archived — 20260904142405-record-each-codex-tick-outcome-and-next-due-time.md
- 2026-09-04 — ticket archived — 20260904142405-expose-codex-loop-status-to-the-invoking-session.md
- 2026-09-04 — ticket archived — 20260904143152-define-the-codex-parent-relay-contract.md
- 2026-09-04 — ticket archived — 20260904143152-return-slack-intents-from-codex-worker-ticks.md
- 2026-09-04 — ticket archived — 20260904143152-execute-relayed-slack-operations-in-the-owning-chat.md
- 2026-09-04 — ticket archived — 20260904143152-report-an-unavailable-codex-relay-without-pretending-delivery.md
- 2026-09-04 — mission achieved — mission.md
