---
type: Feedback
title: Live transport and incremental-read evidence
kind: concern
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-08T08:04:10+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: live-transport-and-incremental-read-evidence
owner: 
mission: []
tickets: [20260908031038-unify-loop-transports-and-durable-outbox.md, 20260908031039-make-publication-and-claim-recovery-safe.md, 20260908031040-connect-runtime-capabilities-and-adapters.md, 20260908031041-normalize-inputs-and-continue-strategy-learning.md, 20260908031042-share-discovery-across-manual-entrypoints.md, 20260908031043-resume-delivery-and-preserve-report-sections.md, 20260908031044-reuse-observations-and-bound-polling-cost.md, 20260908031045-finish-loop-contracts-and-portable-migration.md]
origin_pr: 1080
origin_pr_url: https://github.com/qmu/workaholic/pull/1080
origin_branch: work-20260908-043332
origin_commit: 0ef45bad5
last_seen: 2026-09-08T08:04:10+09:00
---

# Live transport and incremental-read evidence

## Description

Real QFS workspace and sender resolution, Slack send/readback, and provider-side incremental pushdown remain unverified (see [39336ca77](https://github.com/qmu/workaholic/commit/39336ca77) in `docs/agentic-loop-migration.md`)

## How to Fix

Run the target-specific QFS and Slack drill, compare provider request volume, and retain returned workspace, channel, timestamp, thread, and sender evidence.
