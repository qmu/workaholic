---
type: Mission
title: Carry claim liveness off the review branch
slug: carry-claim-liveness-off-the-review-branch
status: achieved
merge_policy:
created_at: 2026-09-03T22:25:03+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.9
feedback: [20260903222258-carry-a-claim-s-liveness-somewhere-other-than-an-empty-commit-on-the-work-branch.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260903-225834
---

# Carry claim liveness off the review branch

## Goal

Stop using empty commits on a unit's work branch as its short-lived liveness signal. Preserve
the shared, git-native exclusion and takeover guarantees while keeping review history limited to
the claim and the work a reviewer needs to understand.

## Experience

A live run refreshes a claim through a separate, disposable git coordinate. Every claim reader
reaches the same freshness verdict under Claude Code and Codex, ordinary work branches acquire no
heartbeat commits, and ending a claim retires its liveness state without manual cleanup.

## Acceptance

- [x] The liveness carrier is selected from measured reader and transport behavior, with legacy
      branch-tip claims remaining readable during the transition. (#20260903222521-measure-the-claim-liveness-readers-and-choose-the-off-branch-carrier.md)
- [x] Heartbeats advance only the separate carrier while every exclusion and takeover path reads
      the same freshness decision. (#20260903222521-move-heartbeat-writes-and-claim-freshness-reads-onto-the-liveness-carrier.md)
- [x] Merge, release, and supersession retire the carrier, and a hermetic lifecycle proves that
      pull-request branch history contains no `Refresh heartbeat` commits. (#20260903222521-retire-claim-liveness-state-without-polluting-review-history.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-03 — ticket archived — 20260903222521-measure-the-claim-liveness-readers-and-choose-the-off-branch-carrier.md
- 2026-09-03 — ticket archived — 20260903222521-move-heartbeat-writes-and-claim-freshness-reads-onto-the-liveness-carrier.md
- 2026-09-03 — ticket archived — 20260903222521-retire-claim-liveness-state-without-polluting-review-history.md
- 2026-09-03 — mission achieved — mission.md
- 2026-09-03 — story reported — work-20260903-225834.md
- 2026-09-03 — run recorded (+0.9h) — 20260903-135439
