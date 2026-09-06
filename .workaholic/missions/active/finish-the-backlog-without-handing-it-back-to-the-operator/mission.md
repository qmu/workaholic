---
type: Mission
title: Finish the backlog without handing it back to the operator
slug: finish-the-backlog-without-handing-it-back-to-the-operator
status: active
merge_policy:
created_at: 2026-09-06T08:18:43+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260906081415-make-work-own-completion-on-codex-and-claude-code.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260906-092226
---

# Finish the backlog without handing it back to the operator

## Goal

`/work` must reach what a capable coding agent reaches asked directly: recover the open
PRs, resolve conflicts, repair checks, merge in order, drain the queue. Measured: 28
tickets waiting, **zero claimable units, no implement worker**, four conflicting PRs.
Handoffs narrow to verified external limits. **Codex first.**

## Experience

The loop finishes what it was given. A tick with nothing newly claimable still dispatches
the pass that works the open recovery and delivery states; a conflict, a red check or a
stale handoff assumption is worked, not handed over, and other work continues past a real
limit. A worker's finish rests on what it reported, not its exit status; progress and
completion reach the operator or are named undelivered.

## Acceptance

- [x] A tick with no newly claimable ticket still dispatches a pass acting on the open
      recovery and delivery states. (#20260906082031-count-recovery-and-delivery-work-as-claimable.md)
- [ ] A worker's finish comes from its own reported outcome; one exiting zero without
      executing is not finished. (#20260906082031-record-a-worker-s-finish-from-its-own-reported-outcome.md)
- [ ] One `/work` run drains a seeded backlog holding a conflicting PR, an undelivered
      one and a parked claim, its reports proved delivered. (#20260906082031-drain-a-seeded-backlog-in-one-work-run-end-to-end.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-06 — ticket archived — 20260906082031-count-recovery-and-delivery-work-as-claimable.md
- 2026-09-06 — ticket archived — 20260906082031-give-a-dispatched-codex-worker-the-whole-role-it-is-named-for.md
