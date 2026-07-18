---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
last_seen: 2026-07-16T12:06:03+09:00
first_seen: 2026-07-01T21:16:06+09:00
concern_id: catch-deployment-attribution-is-approximate
severity: moderate
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Promoted to ticket 20260716163002-catch-scan-window-blind-spots.md (2026-07-16 triage-to-zero): stamp the deployer into record-evidence.sh's block and read it back. Risk now tracked in the queue.
closed_at: 2026-07-16T17:09:32+09:00
---

# (carried from PR #63) /catch deployment attribution is approximate

## Description

Stories and release notes carry no author, so a deployment is attributed to the git author of the commit that last touched the story (see `plugins/workaholic/skills/catch/scripts/scan-window.sh`).

## How to Fix

Have `/ship`'s `record-evidence.sh` stamp an explicit author into the Deployment Evidence block so the join reads a recorded author instead of inferring one.

