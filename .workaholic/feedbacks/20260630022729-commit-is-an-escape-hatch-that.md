---
type: Feedback
title: (carried from PR #59) /commit is an escape hatch that can invite non-ticketed commits
kind: concern
source: development
created_at: 2026-06-30T02:27:29+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: commit-is-an-escape-hatch-that
owner: 
mission: 
tickets: []
origin_pr: 60
origin_pr_url: https://github.com/qmu/workaholic/pull/60
origin_branch: work-20260630-011820
origin_commit: 7a2c78d
last_seen: 2026-06-30T02:27:29+09:00
closed: superseded
---

# (carried from PR #59) /commit is an escape hatch that can invite non-ticketed commits

## Description

The `/commit` command provides a sanctioned ad-hoc commit path, but by existing it can normalize committing outside the ticketed `/drive` flow (`plugins/workaholic/commands/commit.md`). It is still strictly better than free-handed `git commit`.

## How to Fix

Keep the command copy steering users to `/drive` for ticketed work; revisit if history shows `/commit` displacing ticketed development.
