---
origin_pr: 43
origin_pr_url: https://github.com/qmu/workaholic/pull/43
origin_branch: work-20260617-000311
origin_commit: 1ed7fbb
created_at: 2026-06-17T01:51:15+09:00
severity: low
status: resolved
resolved_by_pr: 49
resolved_by_commit: e390172
---

# Carry-over pipeline accumulates duplicates

## Description

`41-*` and `42-carried-from-pr-41-*` are the same two concerns re-carried; `extract-carryover.sh` re-emits identical concerns each ship, so they compound across PRs (this story's section 6 inherited duplicate pairs).

## How to Fix

Canonicalize concern files by basename/content hash in `extract-carryover.sh` (or the carry-over judge) so duplicates merge rather than re-emit.
