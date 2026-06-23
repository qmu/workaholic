---
origin_pr: 49
origin_pr_url: https://github.com/qmu/workaholic/pull/49
origin_branch: work-20260618-003119
origin_commit: b15fbd0
created_at: 2026-06-18T08:13:13+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# Existing carry-over corpus still contains chained duplicates from before the dedup fix

## Description

This branch stops *new* duplication, but the ~17 still-active concerns already include chained duplicates accumulated before the fix (e.g. `41-…` carried as `42-carried-from-41-…`, `43-…`, `44-…`). The dedup in [e390172](https://github.com/qmu/workaholic/commit/e390172) prevents re-emission going forward but does not retro-merge what is already there (`.workaholic/concerns/`).

## How to Fix

Run a one-time housekeeping pass that canonicalizes and merges existing duplicate carry chains into a single concern file each, archiving the merged duplicates — a scoped cleanup ticket, distinct from the forward-looking dedup landed here.
