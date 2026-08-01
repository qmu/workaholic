---
type: Feedback
title: The mission half of the queue test is O(tickets) git calls per claim
kind: concern
source: development
created_at: 2026-08-01T11:15:51+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-mission-half-of-the-queue
owner: 
mission: 
tickets: [20260801110246-a-reported-unit-is-resumed-forever.md]
origin_pr: 157
origin_pr_url: https://github.com/qmu/workaholic/pull/157
origin_branch: work-20260801-110823
origin_commit: 327a89e1
last_seen: 2026-08-01T11:15:51+09:00
---

# The mission half of the queue test is O(tickets) git calls per claim

## Description

For a mission unit the check reads each `todo/` ticket's frontmatter at the branch tip through `git show`, once per claim per scan. Claims are few and tickets are few, so it is currently cheap, but the scan runs on every survey and every claim attempt (`plugins/workaholic/skills/drive/scripts/lib/claims.sh`).

## How to Fix

If it ever bites, read the whole tree once with `git grep -l` against the branch ref rather than per-file `git show`.
