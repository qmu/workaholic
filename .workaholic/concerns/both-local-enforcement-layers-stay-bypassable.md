---
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-06-29T13:18:46+09:00
last_seen: 2026-06-30T02:27:29+09:00
first_seen: 2026-06-29T13:18:46+09:00
concern_id: both-local-enforcement-layers-stay-bypassable
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Both local enforcement layers stay bypassable and arrive late

## Description

The Bash gate plus the `commit-msg` hook are bypassable via `git commit --no-verify` and on server-side merges, and the git hook reaches a consumer only after release + update and *then* the owner must still run the installer (see [e2fdcf0](https://github.com/qmu/workaholic/commit/e2fdcf0) in `plugins/workaholic/hooks/install-git-hooks.sh`). They are a strong belt, not a vault.

## How to Fix

Pair the local layers with a repo-side control (branch protection / required status check) for true enforcement, and surface the one-line install command prominently in the release/rollout notes so consumers actually opt in.
