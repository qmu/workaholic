---
type: Feedback
title: The archive commit is again over the changed-lines ceiling
kind: concern
source: development
created_at: 2026-08-01T02:55:26+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-archive-commit-is-again-over
owner: 
mission: []
tickets: [20260801003034-worktrees-are-never-reclaimed.md]
origin_pr: 132
origin_pr_url: https://github.com/qmu/workaholic/pull/132
origin_branch: work-20260801-023444
origin_commit: d29e07bf
last_seen: 2026-08-01T02:55:26+09:00
---

# The archive commit is again over the changed-lines ceiling

## Description

551 non-generated lines against a 500 ceiling on [0f5e22c8](https://github.com/qmu/workaholic/commit/0f5e22c8) — marginal, and the second consecutive branch to hit it, because `archive.sh` emits exactly one commit per ticket.

## How to Fix

Belongs to the open mission *Make the per-commit changed-lines ceiling a rule that holds*; the pattern across two branches is now evidence for that decision rather than a one-off.
