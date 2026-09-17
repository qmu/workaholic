---
type: Mission
title: Reconcile waiting work without repeated machine claims
slug: reconcile-waiting-work-without-repeated-machine-claims
status: active
merge_policy:
created_at: 2026-09-17T17:36:07+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260917173545-stop-re-claiming-units-that-await-a-person.md, 20260917173553-reconcile-historical-loop-state-without-coordinator-handwork.md]
tickets: [20260917173645-adopt-live-work-and-collapse-duplicate-claims.md, 20260917173645-hold-person-dependent-units-outside-the-machine-claim-pool.md, 20260917173645-own-every-reconciliation-action-before-returning-to-cadence.md]
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260917-182253
---

# Reconcile waiting work without repeated machine claims

## Goal

既存の claim・worktree・runner・handoff を一度の reconciliation で収束させ、person 待ちの unit を機械が再claimせず、coordinator の手作業なしで通常 cadence に戻す。

## Experience

長時間 loop は restart 後も live state を採用し、同じ unit を重複実行せず、person 待ちを保留したまま独立 work を継続し、必要な agent action を必ず所有者へ割り当てる。

## Acceptance

- [x] Reconciliation が live worktree、stacked inheritance、重複 runner を一意な active ownership に収束させる。 (#20260917173645-adopt-live-work-and-collapse-duplicate-claims.md)
- [x] unanswered `handoff-unit:` または awaiting-person state の unit は再claimされず、回答後だけ再び eligible になる。 (#20260917173645-hold-person-dependent-units-outside-the-machine-claim-pool.md)
- [ ] `needs_agent` action は同tickのdispatchまたは durable follow-up receiptのいずれかに必ず所有される。 (#20260917173645-own-every-reconciliation-action-before-returning-to-cadence.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-17 — ticket archived — 20260917173645-adopt-live-work-and-collapse-duplicate-claims.md
- 2026-09-17 — ticket archived — 20260917173645-hold-person-dependent-units-outside-the-machine-claim-pool.md
