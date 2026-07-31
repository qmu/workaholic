---
type: Feedback
title: Six existing missions are over the new ceiling
kind: concern
source: development
created_at: 2026-08-01T02:52:42+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: six-existing-missions-are-over-the
owner: 
mission: []
tickets: [20260801012129-cap-mission-size-and-drop-the-scope-section.md]
origin_pr: 131
origin_pr_url: https://github.com/qmu/workaholic/pull/131
origin_branch: work-20260801-022239
origin_commit: fe0c5bcb
last_seen: 2026-08-01T02:52:42+09:00
---

# Six existing missions are over the new ceiling

## Description

Measured now, `adopt-a-git-flow-branching-model-with-durable-ship-records` is 151 lines / 9 KB / 8 acceptance items against 60 / 2048 / 3. Nothing rewrites them, which is correct — history is not migrated — but the roadmap still shows lists that will not get ticked.

## How to Fix

Replan is the sanctioned path: `/mission "<instruction>"` can drop now-moot criteria, and each drop is recorded as its own changelog line. That is the developer's call per mission, not a sweep.
