---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T21:16:06+09:00
concern_id: catch-deployment-attribution-is-approximate
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #63) /catch deployment attribution is approximate

## Description

`/catch` deployment attribution is approximate because the join keys on branch-story ship commits; this branch's fetch/remote-scan change did not touch that join, so the approximation remains (deferred concern `.workaholic/concerns/63-catch-deployment-attribution-is-approximate-for.md`).

## How to Fix

Tighten the deployment-attribution join to a more precise key than ship-commit matching.
