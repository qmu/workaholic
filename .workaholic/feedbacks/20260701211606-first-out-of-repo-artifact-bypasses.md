---
type: Feedback
title: (carried from PR #67) First out-of-repo artifact bypasses the layout hook
kind: concern
source: development
created_at: 2026-07-01T21:16:06+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: first-out-of-repo-artifact-bypasses
owner: 
mission: 
tickets: []
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
last_seen: 2026-07-01T21:16:06+09:00
closed: superseded
---

# (carried from PR #67) First out-of-repo artifact bypasses the layout hook

## Description

The first out-of-repo artifact bypasses the artifact-layout hook, so its placement is unguarded (deferred concern `.workaholic/concerns/67-first-out-of-repo-artifact-bypasses.md`).

## How to Fix

Extend the layout guard to cover the first out-of-repo artifact case.
