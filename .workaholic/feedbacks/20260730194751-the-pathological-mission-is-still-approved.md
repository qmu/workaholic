---
type: Feedback
title: The pathological mission is still approved, and only the survey now declines it
kind: concern
source: development
created_at: 2026-07-30T19:47:51+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-pathological-mission-is-still-approved
owner: 
mission: []
tickets: [20260730180248-claim-reader-loses-artifacts-on-archive.md, 20260730181500-plan-floor-counts-acceptance-not-queue.md]
origin_pr: 112
origin_pr_url: https://github.com/qmu/workaholic/pull/112
origin_branch: work-20260730-191139
origin_commit: dfaaf654
last_seen: 2026-07-30T19:47:51+09:00
---

# The pathological mission is still approved, and only the survey now declines it

## Description

`adopt-a-git-flow-branching-model-with-durable-ship-records` remains `status: approved` with `merge_policy: auto`, `tickets: []`, and an acceptance sketch that says it is not a plan. This change stops it being *offered*, which is the code's part; it deliberately does not demote it, because flipping another actor's approved mission back to `draft` from inside an unattended run would be a run overriding a human ruling. So the repository still holds an approved mission that no floor would approve today (see [ac4a87cc](https://github.com/qmu/workaholic/commit/ac4a87cc)).

## How to Fix

Replan it — `/mission <instruction referencing it>` — which emits the ticket set its acceptance sketch is a proposal for, and re-approves it through the flow that now checks the queue. Until then it sits in `active/` looking drive-ready and being excluded, which is honest but easy to misread.
