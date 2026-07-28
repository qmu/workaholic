---
type: Feedback
title: (carried from PR #41) Script rename requires stale-artifact cleanup
kind: concern
source: development
created_at: 2026-06-17T20:14:03+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: script-rename-requires-stale-artifact-cleanup
owner: 
mission: 
tickets: []
origin_pr: 44
origin_pr_url: https://github.com/qmu/workaholic/pull/44
origin_branch: work-20260617-082241
origin_commit: ba49fe6
last_seen: 2026-06-17T20:14:03+09:00
closed: resolved
---

# (carried from PR #41) Script rename requires stale-artifact cleanup

## Description

When a bundled skill script is renamed, `build.mjs` picks up the new name but does not delete the orphaned old artifact (it had to be manually staged for deletion to avoid freshness-CI drift).

## How to Fix

Add a cleanup pass to `build.mjs` to remove orphaned generated scripts after regeneration.
