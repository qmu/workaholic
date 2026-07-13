---
origin_pr: 48
origin_pr_url: https://github.com/qmu/workaholic/pull/48
origin_branch: work-20260617-231848
origin_commit: 63bbb9e
created_at: 2026-06-18T00:21:49+09:00
last_seen: 2026-06-18T00:21:49+09:00
first_seen: 2026-06-18T00:21:49+09:00
concern_id: deploy-on-merge-vs-deploy-from
severity: low
status: resolved
resolved_by_pr: 55
resolved_by_commit: 9f754dc
---

# Deploy-on-merge vs deploy-from-branch needs clearer guidance in the contract template

## Description

The reordered flow's "confirm before merge" cleanly fits branch-deploy-then-merge, but deploy-on-merge projects (the release is published *from* the merge commit) must split confirmation into pre-merge readiness and post-merge promotion — as `.workaholic/deployments/marketplace.md` does. New users may not infer that split from the README template (`.workaholic/deployments/README.md`).

## How to Fix

Expand the deployments README/template with both models spelled out and a copyable deploy-on-merge example, and add prose to the §1 Deployment Contract describing when each applies.
