---
origin_pr: 60
origin_pr_url: https://github.com/qmu/workaholic/pull/60
origin_branch: work-20260630-011820
origin_commit: 7a2c78d
created_at: 2026-06-30T02:27:29+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #59) /commit is an escape hatch that can invite non-ticketed commits

## Description

The `/commit` command provides a sanctioned ad-hoc commit path, but by existing it can normalize committing outside the ticketed `/drive` flow (`plugins/workaholic/commands/commit.md`). It is still strictly better than free-handed `git commit`.

## How to Fix

Keep the command copy steering users to `/drive` for ticketed work; revisit if history shows `/commit` displacing ticketed development.
