---
type: Feedback
title: The off-base extraction now costs a fetch and a worktree
kind: concern
source: development
created_at: 2026-07-30T19:54:39+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-off-base-extraction-now-costs
owner: 
mission: []
tickets: [20260730190856-merge-pr-breaks-in-a-claim-worktree.md]
origin_pr: 113
origin_pr_url: https://github.com/qmu/workaholic/pull/113
origin_branch: work-20260730-193046
origin_commit: 921d0cbc
last_seen: 2026-07-30T19:54:39+09:00
---

# The off-base extraction now costs a fetch and a worktree

## Description

When not already on the base, the extraction opens a publish tree — a fetch plus a `git worktree add` — runs, publishes, and tears it down (see [7642ebaa](https://github.com/qmu/workaholic/commit/7642ebaa) in `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh`). That is the only route that can write to the base from a merged branch's checkout, so the cost is inherent rather than incidental, but it is new work on the `auto` ship path and it can fail for its own reasons (`no_origin`, `dirty_publish_tree`) that have nothing to do with concerns.

## How to Fix

Nothing now. If `/drive` ever ships many `auto` units in one run, hold one publish tree open across them rather than opening one per unit — the primitive is idempotent on open, so the change is in the caller, not the script.
