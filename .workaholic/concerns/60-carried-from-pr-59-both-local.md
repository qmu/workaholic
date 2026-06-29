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

# (carried from PR #59) Both local enforcement layers stay bypassable and arrive late

## Description

The Bash gate plus the `commit-msg` hook are bypassable via `git commit --no-verify` and on server-side merges, and the git hook reaches a consumer only after release + update and an explicit install (`plugins/workaholic/hooks/install-git-hooks.sh`).

## How to Fix

Pair the local layers with a repo-side control (branch protection / required status check), and surface the one-line install command prominently in rollout notes.
