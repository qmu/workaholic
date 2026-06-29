---
origin_pr: 60
origin_pr_url: https://github.com/qmu/workaholic/pull/60
origin_branch: work-20260630-011820
origin_commit: 7a2c78d
created_at: 2026-06-30T02:27:29+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #59) Gate coverage is the single-Bash-call agent surface only

## Description

The `PreToolUse(Bash)` commit gate blocks off-policy subjects only and sees only the agent's top-level Bash command (`plugins/workaholic/hooks/guard-git-commit.sh`); terminal `git commit`, `--no-verify`, web/server merges, and non-Bash agent paths are out of scope.

## How to Fix

Treat the Bash gate as one belt in a stack: install the `commit-msg` hook for local-human coverage and add server-side branch protection for the remote surface.
