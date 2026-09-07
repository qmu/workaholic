---
type: Feedback
title: Integrated release exceeds scan size guidance
kind: concern
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-08T08:04:10+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: integrated-release-exceeds-scan-size-guidance
owner: 
mission: []
tickets: [20260908031038-unify-loop-transports-and-durable-outbox.md, 20260908031039-make-publication-and-claim-recovery-safe.md, 20260908031040-connect-runtime-capabilities-and-adapters.md, 20260908031041-normalize-inputs-and-continue-strategy-learning.md, 20260908031042-share-discovery-across-manual-entrypoints.md, 20260908031043-resume-delivery-and-preserve-report-sections.md, 20260908031044-reuse-observations-and-bound-polling-cost.md, 20260908031045-finish-loop-contracts-and-portable-migration.md]
origin_pr: 1080
origin_pr_url: https://github.com/qmu/workaholic/pull/1080
origin_branch: work-20260908-043332
origin_commit: 0ef45bad5
last_seen: 2026-09-08T08:04:10+09:00
---

# Integrated release exceeds scan size guidance

## Description

The final branch changes 408 files, includes the 736956-byte loop drill, and contains two implementation commits above the 500-line guidance (see [aa0e228dc](https://github.com/qmu/workaholic/commit/aa0e228dc) and [4cdef2c18](https://github.com/qmu/workaholic/commit/4cdef2c18))

## How to Fix

Review and accept the override for this intentionally integrated P3-P9 release; future independent changes should return to smaller commit units.
