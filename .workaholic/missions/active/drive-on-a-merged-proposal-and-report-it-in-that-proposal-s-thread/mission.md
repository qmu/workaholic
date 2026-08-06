---
type: Mission
title: Drive on a merged proposal, and report it in that proposal's thread
slug: drive-on-a-merged-proposal-and-report-it-in-that-proposal-s-thread
status: active
merge_policy:
created_at: 2026-08-05T13:04:17+00:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours: 0.7
feedback: [20260805130407-trigger-the-drive-routine-on-a-merged-proposal-and-report-start-and-completion-in-its-thread]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260806-152604
---

# Drive on a merged proposal, and report it in that proposal's thread

## Goal

`[Drive]` fires on a clock and takes whatever the survey offers, so a proposal's
merge and the run that implements it are unrelated events reported in unrelated
places. Join them: the run starts because a proposal merged, and it says so —
beginning and end — in that proposal's own thread.

## Experience

A developer merges a proposal's pull request. The thread they proposed it in gains
a reply saying implementation has started, and later one saying it finished, each
naming the unit's pull request. The item's whole life is readable in that one
thread, without going looking for it.

## Acceptance

<!-- PROPOSED criteria — a sketch for discussion, not a plan. -->

- [x] A merged proposal starts a drive run for that proposal's work, and what the
      clock still owes — handoff resumption, lapsed claims, backlog nobody proposed
      — is decided and written down rather than dropped by omission. (#20260805130456-start-the-drive-routine-on-a-merged-proposal.md)
- [x] A drive run reports implementation started and finished into the feedback
      item's thread, keyed from the unit's own `feedback:` refs, leaving the
      existing three-case thread routing and its fallback unchanged. (#20260805130457-report-drive-start-and-finish-in-the-item-s-thread.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-05 — ticket archived — 20260805130456-start-the-drive-routine-on-a-merged-proposal.md
- 2026-08-05 — ticket archived — 20260805130457-report-drive-start-and-finish-in-the-item-s-thread.md
- 2026-08-05 — story reported — work-20260805-221704.md
- 2026-08-05 — run recorded (+0.7h) — 20260805-221704
