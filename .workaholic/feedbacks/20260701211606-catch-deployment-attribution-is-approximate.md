---
type: Feedback
title: (carried from PR #63) /catch deployment attribution is approximate
kind: concern
source: development
created_at: 2026-07-01T21:16:06+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: catch-deployment-attribution-is-approximate
owner: 
mission: 
tickets: []
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
last_seen: 2026-07-16T12:06:03+09:00
closed: accepted
---

# (carried from PR #63) /catch deployment attribution is approximate

## Description

Stories and release notes carry no author, so a deployment is attributed to the git author of the commit that last touched the story (see `plugins/workaholic/skills/catch/scripts/scan-window.sh`).

## How to Fix

Have `/ship`'s `record-evidence.sh` stamp an explicit author into the Deployment Evidence block so the join reads a recorded author instead of inferring one.
