---
type: Feedback
title: A `git add -A` caller still sweeps the migration's unstaged work
kind: concern
source: development
created_at: 2026-08-04T12:34:27+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-git-add-a-caller-still
owner: 
mission: []
tickets: [20260804023000-readonly-scripts-commit-git-index.md]
origin_pr: 179
origin_pr_url: https://github.com/qmu/workaholic/pull/179
origin_branch: work-20260804-111346
origin_commit: f964a213
last_seen: 2026-08-04T12:34:27+09:00
---

# A `git add -A` caller still sweeps the migration's unstaged work

## Description

Leaving the migration's records unstaged fixes a caller that stages by

## How to Fix

Have the seams that *want* the migration committed (ship extraction, the
