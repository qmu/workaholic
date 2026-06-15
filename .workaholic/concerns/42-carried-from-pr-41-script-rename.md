---
origin_pr: 42
origin_pr_url: https://github.com/qmu/workaholic/pull/42
origin_branch: work-20260528-122941
origin_commit: 0915802
created_at: 2026-06-16T08:57:05+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #41) Script rename requires stale artifact cleanup

## Description

A proposed orphan-cleanup pass in `build.mjs` to remove old-named script artifacts after cross-skill reference renaming did not land; only `lookupVersion` and `PUBLIC_SUBSTITUTIONS` additions shipped.

## How to Fix

Defer orphan cleanup to a follow-up ticket after confirming the current rename strategy won't create orphaned copies in `dist/`. Low urgency.
