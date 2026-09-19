---
type: Mission
title: Dispatch bounded workers without stopping the observation clock
slug: dispatch-bounded-workers-without-stopping-the-observation-clock
status: active
merge_policy:
created_at: 2026-09-19T09:55:46+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260919095501-support-low-context-workers-without-stalling-the-work-tick.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260919-133920
---

# Dispatch bounded workers without stopping the observation clock

## Goal

An operator turned subagents off because each child inherited the whole conversation. Honouring
that meant implementing in the parent — and the coordinator, still running, stopped receiving role
ticks. The loop exposes a worker **count** and a **cadence** and nothing about a child's context
cost, so the operator had one lever and it was the wrong one.

## Experience

An operator bounds what a child inherits without turning delegation off, and the clock keeps
running either way. A restriction that costs a guarantee says which one, instead of quietly
becoming a long inline turn. Changing the policy keeps the same instance, anchor and receipts.

## Acceptance

<!-- PROPOSED - a sketch the reviewer replans drive-ready. -->

- [x] A context propagation policy is declared and reported separately from count and cadence,
      and a dispatched child carries a bounded input (#20260919095618-declare-a-context-propagation-policy-beside-the-worker-count.md)
- [x] A restricted delegation names the guarantees that lapse and keeps observing, preserving the
      instance, anchor and receipts (#20260919095618-name-the-guarantees-that-lapse-when-delegation-is-restricted.md)
- [ ] A drill proves observation continues during a long implementation (#20260919095618-drill-a-long-implementation-against-a-live-slack-reply.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-19 — ticket archived — 20260919095618-declare-a-context-propagation-policy-beside-the-worker-count.md
- 2026-09-19 — ticket archived — 20260919095618-name-the-guarantees-that-lapse-when-delegation-is-restricted.md
