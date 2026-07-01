---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #67) First out-of-repo artifact bypasses the layout hook

## Description

The first out-of-repo artifact bypasses the artifact-layout hook, so its placement is unguarded (deferred concern `.workaholic/concerns/67-first-out-of-repo-artifact-bypasses.md`).

## How to Fix

Extend the layout guard to cover the first out-of-repo artifact case.
