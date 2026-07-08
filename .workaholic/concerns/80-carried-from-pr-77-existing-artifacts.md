---
type: Concern
mission: 
tickets: [20260707104117-fix-installed-script-helper-resolution.md, 20260707220735-guard-hook-scripts-executable.md, 20260709023255-catch-scan-mission-join.md, 20260709023256-catch-report-missions-section.md]
origin_pr: 80
origin_pr_url: https://github.com/qmu/workaholic/pull/80
origin_branch: work-20260707-104047
origin_commit: cf6a1d8
created_at: 2026-07-09T03:28:39+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #77) Existing artifacts are not backfilled into the .workaholic OKF bundle index

## Description

New `.workaholic` artifacts get OKF frontmatter and are indexed by `refresh-index.sh`; older tickets/stories pre-dating the OKF layer remain unindexed and invisible to OKF consumers.

## How to Fix

Run a backfill to retroactively add OKF frontmatter to eligible artifacts and rebuild the index, or document backfill as out-of-scope with a migration date.
