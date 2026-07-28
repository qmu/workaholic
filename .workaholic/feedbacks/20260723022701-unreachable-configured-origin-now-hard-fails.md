---
type: Feedback
title: Unreachable configured origin now hard-fails mission-worktree creation
kind: concern
source: development
created_at: 2026-07-23T02:27:01+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: unreachable-configured-origin-now-hard-fails
owner: 
mission: []
tickets: [20260722200001-fetch-origin-before-resolving-mission-worktree-base.md]
origin_pr: 95
origin_pr_url: https://github.com/qmu/workaholic/pull/95
origin_branch: work-20260723-000846
origin_commit: 2d6215be
last_seen: 2026-07-28T20:58:24+09:00
---

# Unreachable configured origin now hard-fails mission-worktree creation

## Description

`create-mission-worktree.sh` hard-fails when origin is configured but unreachable, leaving no offline escape hatch. Fail-loud was the mandated trade-off. (See PR #95)

## How to Fix

If this bites in practice, relax to a loud local fallback (stderr note + proceed) rather than a hard failure.
