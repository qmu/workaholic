---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
last_seen: 2026-07-15T20:55:56+09:00
first_seen: 2026-07-01T21:16:06+09:00
concern_id: catch-deployment-attribution-is-approximate
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #63) /catch deployment attribution is approximate

## Description

Stories and release notes carry no author, so a deployment is attributed to the git author of the commit that last touched the story (see `plugins/workaholic/skills/catch/scripts/scan-window.sh`).

## How to Fix

Have `/ship`'s `record-evidence.sh` stamp an explicit author into the Deployment Evidence block so the join reads a recorded author instead of inferring one.

