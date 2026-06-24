---
origin_pr: 56
origin_pr_url: https://github.com/qmu/workaholic/pull/56
origin_branch: work-20260624-140219
origin_commit: e78465d
created_at: 2026-06-24T21:39:11+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #49) Carry-over corpus contains chained duplicates

## Description

Active concerns still include chained duplicates accumulated before the dedup fix (`.workaholic/concerns/49-existing-carry-over-corpus-still-contains.md`).

## How to Fix

Land the triage branch which canonicalizes and archives the duplicate chains.
