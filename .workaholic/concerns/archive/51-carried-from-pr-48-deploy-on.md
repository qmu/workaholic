---
origin_pr: 51
origin_pr_url: https://github.com/qmu/workaholic/pull/51
origin_branch: work-20260618-115347
origin_commit: 92d1717
created_at: 2026-06-18T17:08:51+09:00
last_seen: 2026-06-18T17:08:51+09:00
first_seen: 2026-06-18T17:08:51+09:00
concern_id: deploy-on-merge-vs-deploy-from
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #48) Deploy-on-merge vs deploy-from-branch needs clearer guidance in the contract template

## Description

The reordered flow's "confirm before merge" cleanly fits branch-deploy-then-merge, but deploy-on-merge projects (the release is published *from* the merge commit) must split confirmation into pre-merge readiness and post-merge promotion — as `.workaholic/deployments/marketplace.md` does. New users may not infer that split from the README template (`.workaholic/deployments/README.md`).

## How to Fix

Expand the deployments README/template with both models spelled out and a copyable deploy-on-merge example, and add prose to the §1 Deployment Contract describing when each applies.
