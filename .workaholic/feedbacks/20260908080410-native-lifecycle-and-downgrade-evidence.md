---
type: Feedback
title: Native lifecycle and downgrade evidence
kind: concern
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-08T08:04:10+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: native-lifecycle-and-downgrade-evidence
owner: 
mission: []
tickets: [20260908031038-unify-loop-transports-and-durable-outbox.md, 20260908031039-make-publication-and-claim-recovery-safe.md, 20260908031040-connect-runtime-capabilities-and-adapters.md, 20260908031041-normalize-inputs-and-continue-strategy-learning.md, 20260908031042-share-discovery-across-manual-entrypoints.md, 20260908031043-resume-delivery-and-preserve-report-sections.md, 20260908031044-reuse-observations-and-bound-polling-cost.md, 20260908031045-finish-loop-contracts-and-portable-migration.md]
origin_pr: 1080
origin_pr_url: https://github.com/qmu/workaholic/pull/1080
origin_branch: work-20260908-043332
origin_commit: 0ef45bad5
last_seen: 2026-09-08T08:04:10+09:00
---

# Native lifecycle and downgrade evidence

## Description

Native UI interruption, two foreground automatic reports, and downgrade recovery from interrupted external effects have hermetic contract evidence only (see [39336ca77](https://github.com/qmu/workaholic/commit/39336ca77) in `docs/agentic-loop-migration.md`)

## How to Fix

Exercise both native hosts through interruption, restart, and downgrade, retaining receipts that prove no duplicate dispatch, send, merge, or lost input.
