---
type: Feedback
title: The rebase-and-retry bound is untested under real contention
kind: concern
source: development
created_at: 2026-07-30T18:57:14+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-rebase-and-retry-bound-is
owner: 
mission: []
tickets: [20260729183606-publish-tree-primitive.md, 20260729183607-ticket-publishes-to-main.md, 20260729183608-mission-publishes-to-main.md, 20260729183609-drive-surveys-current-main.md]
origin_pr: 108
origin_pr_url: https://github.com/qmu/workaholic/pull/108
origin_branch: work-20260730-171125
origin_commit: 39b52709
last_seen: 2026-07-30T18:57:14+09:00
---

# The rebase-and-retry bound is untested under real contention

## Description

`publish-tree-commit.sh` answers a non-fast-forward with exactly one rebase-and-retry and then reports `diverged` (see [1179d916](https://github.com/qmu/workaholic/commit/1179d916) in `plugins/workaholic/skills/branching/scripts/publish-tree-commit.sh`). The bound is deliberate — an unbounded loop hides sustained divergence a human should see — and the single-retry path is covered by a two-clone test. What is not known is how often the *second* attempt loses in practice once two crons and interactive sessions all publish to one `main`.

## How to Fix

Watch for `diverged` in the loop logs. If it appears, revisit the bound with the observed contention rate rather than raising it blindly; a second retry is cheap, an unbounded loop is not.
