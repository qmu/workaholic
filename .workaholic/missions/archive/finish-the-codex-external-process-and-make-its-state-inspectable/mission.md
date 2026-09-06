---
type: Mission
title: Finish the Codex external process and make its state inspectable
slug: finish-the-codex-external-process-and-make-its-state-inspectable
status: achieved
merge_policy:
created_at: 2026-09-06T10:20:47+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260906101722-finish-codex-support-as-an-external-process-with-inspectable-state.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260906-125643
---

# Finish the Codex external process and make its state inspectable

## Goal

The operator asked, unreachable on a flight, that Codex support be carried to completion as an
**external process** and proved from state a person can look at rather than from a chat.
Measured on their own machine at the hour of the ask: `.codex-loop/` exists and is **empty** —
no `status.json`, no transcript, no worker record — while the loop was believed to be turning.
That directory is written by `codex-loop.sh` alone, so "never started" and "died before its
first tick" read identically as absent.

## Experience

The Codex side of the loop starts as a plain external process, and what it is doing is
answerable from its state directory alone — without a chat, a live lock probe, or the account
that started it. A supervisor that never ran, one that died, one mid-tick and one whose worker
failed are four distinct readings. A degraded read says so and never reads as healthy.

## Acceptance

- [x] The empty-directory reading is reproduced and localized, and "never started" is
      distinguishable from "started and stopped" in the directory itself. (#20260906102220-reproduce-and-localize-the-empty-codex-state-directory.md)
- [x] Each dispatched worker's state and last outcome are readable as data in the state
      directory, not only as a live lock probe. (#20260906102221-record-each-codex-worker-s-state-and-last-outcome-as-data.md)
- [x] `--status` answers the whole question — supervisor and every worker — from the directory
      alone, naming an unreadable part rather than omitting it. (#20260906102221-answer-the-whole-codex-loop-status-from-the-directory-alone.md)

## Changelog

- 2026-09-06 — ticket archived — 20260906102220-reproduce-and-localize-the-empty-codex-state-directory.md
- 2026-09-06 — ticket archived — 20260906102220-record-the-supervisor-s-own-liveness-in-the-state-directory.md
- 2026-09-06 — ticket archived — 20260906102221-record-each-codex-worker-s-state-and-last-outcome-as-data.md
- 2026-09-06 — ticket archived — 20260906102221-answer-the-whole-codex-loop-status-from-the-directory-alone.md
- 2026-09-06 — mission achieved — mission.md
- 2026-09-06 — story written — work-20260906-125643.md
