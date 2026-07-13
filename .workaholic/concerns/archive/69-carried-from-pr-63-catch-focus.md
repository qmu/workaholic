---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
superseded_by: catch-focus-buckets-are-utc-day
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T21:16:06+09:00
concern_id: catch-focus-buckets-are-utc-day
severity: moderate
status: superseded
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #63) /catch focus buckets are UTC-day based

## Description

`/catch` focus buckets are computed on UTC days, so activity is bucketed against UTC rather than the developer's local day (deferred concern `.workaholic/concerns/63-catch-focus-buckets-are-utc-day.md`).

## How to Fix

Make the bucket boundary timezone-aware or document the UTC assumption in the report.
