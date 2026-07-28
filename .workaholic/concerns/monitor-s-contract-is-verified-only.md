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
last_seen: 2026-07-28T20:58:24+09:00
severity: moderate
status: active
compound: true
resolved_by_pr: 
resolved_by_commit: 
---

# Monitor's contract is verified only by prose sentinels while its side-effecting dev-env lifecycle has no functional coverage

## Description

Monitor's pre-flight reevaluation, mission-state tracking, and dev-environment lifecycle are validated by cross-references in prose, not executable tests. Untouched by this branch — note the fourth-round decision (I1/G1) slates `/monitor` for retirement into the unified `/drive`, which will resolve or relocate this surface. (See PR #88)

## How to Fix

Add hermetic tests for the functional seams — or fold the requirement into the phase-3 `/drive` unification that absorbs them.

