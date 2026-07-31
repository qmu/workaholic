---
type: Feedback
title: An unmerged proposal blocks its own mission's replan
kind: concern
source: development
created_at: 2026-08-01T02:11:56+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: an-unmerged-proposal-blocks-its-own
owner: 
mission: []
tickets: [20260731163049-propose-surveys-repo-state-and-lands-on-a-branch.md]
origin_pr: 124
origin_pr_url: https://github.com/qmu/workaholic/pull/124
origin_branch: work-20260801-012313
origin_commit: ea3765b8
last_seen: 2026-08-01T02:11:56+09:00
---

# An unmerged proposal blocks its own mission's replan

## Description

`/mission` replan works against the mission as published on `main`, so a mission still sitting in an unmerged pull request cannot be replanned. The command now says so, but the constraint is new — under J1 the mission was always on `main` by the time anyone could reference it (`plugins/workaholic/commands/mission.md`).

## How to Fix

Merge the proposal's PR first. If that friction proves common, replan could resolve a mission from an open PR's branch, but that is a real design question rather than an oversight.
