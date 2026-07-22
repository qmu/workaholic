---
type: Concern
concern_id: monitor-s-contract-is-verified-only
mission: 
tickets: []
origin_pr: 88
origin_pr_url: https://github.com/qmu/workaholic/pull/88
origin_branch: work-20260716-152211
origin_commit: 70e5f3fb
created_at: 2026-07-21T10:28:38+09:00
first_seen: 2026-07-18T20:46:34+09:00
last_seen: 2026-07-22T17:15:01+09:00
severity: moderate
status: active
compound: true
resolved_by_pr: 
resolved_by_commit: 
---

# Monitor's contract is verified only by prose sentinels while its side-effecting dev-env lifecycle has no functional coverage

## Description

Monitor orchestrates leaf work across worktrees and allocates dev environment ports; the pre-flight reevaluation, mission-state tracking, and environment lifecycle are validated by cross-references in prose, not executable tests. Recent branches added new side-effecting monitor/mission scripts but no hermetic tests for monitor's dev-env allocation/cleanup, reevaluation, or worktree-isolation seams; that functional surface stays uncovered.

## How to Fix

Add hermetic tests for monitor's functional seams: reevaluation logic, worktree isolation, and dev-environment allocation and cleanup.

