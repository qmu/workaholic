---
origin_pr: 51
origin_pr_url: https://github.com/qmu/workaholic/pull/51
origin_branch: work-20260618-115347
origin_commit: 92d1717
created_at: 2026-06-18T17:08:51+09:00
last_seen: 2026-06-18T17:08:51+09:00
first_seen: 2026-06-18T17:08:51+09:00
concern_id: existing-carry-over-corpus-still-contains
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #49) Existing carry-over corpus still contains chained duplicates from before the dedup fix

## Description

The dedup fix stops *new* duplication, but the still-active concerns already include chained duplicates accumulated before the fix (e.g. `41-…` carried as `42-carried-from-41-…`, `43-…`, `44-…`). The dedup in [e390172](https://github.com/qmu/workaholic/commit/e390172) prevents re-emission going forward but does not retro-merge what is already there (`.workaholic/concerns/`).

## How to Fix

Run a one-time housekeeping pass that canonicalizes and merges existing duplicate carry chains into a single concern file each, archiving the merged duplicates — a scoped cleanup ticket, distinct from the forward-looking dedup already landed.
