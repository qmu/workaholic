---
type: Concern
mission: 
tickets: [20260713103820-mission-active-archive-split-and-close.md]
origin_pr: 82
origin_pr_url: https://github.com/qmu/workaholic/pull/82
origin_branch: work-20260713-102453
origin_commit: 5d2efad
created_at: 2026-07-13T11:56:22+09:00
last_seen: 2026-07-16T12:06:03+09:00
first_seen: 2026-07-13T11:56:22+09:00
concern_id: hermetic-tests-prove-migration-not-local
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Hermetic tests prove migration, not local use (repo has no missions)

## Description

`.workaholic/missions/` does not exist in this repo, so the living layout migration is exercised only by throwaway fixtures — confirmed again this branch, where all 12 tickets carry an empty `mission:` (see `scripts/test-workflow-scripts.mjs`). This bit directly on [b75b83c0](https://github.com/qmu/workaholic/commit/b75b83c0), whose gate step 4 asked for a real-repository check and could not run one.

## How to Fix

Close only once the mission scripts have run on a real consumer repo that adopted the flat layout.

