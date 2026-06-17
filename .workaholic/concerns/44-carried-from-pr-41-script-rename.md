---
origin_pr: 44
origin_pr_url: https://github.com/qmu/workaholic/pull/44
origin_branch: work-20260617-082241
origin_commit: ba49fe6
created_at: 2026-06-17T20:14:03+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #41) Script rename requires stale-artifact cleanup

## Description

When a bundled skill script is renamed, `build.mjs` picks up the new name but does not delete the orphaned old artifact (it had to be manually staged for deletion to avoid freshness-CI drift).

## How to Fix

Add a cleanup pass to `build.mjs` to remove orphaned generated scripts after regeneration.
