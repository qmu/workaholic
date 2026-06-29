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

# (carried from PR #59) Bundled script hardened without rebuilding outputs/

## Description

Bundled scripts in the drive/report/ship/create-ticket closure must be rebuilt into `outputs/` in lockstep or source and artifact diverge — a stale public copy can fail on non-Claude agents while local tests pass (`plugins/workaholic/skills/branching/scripts/ensure-worktree.sh`).

## How to Fix

When editing any script under a bundled skill closure, run `node scripts/build-plugins/build.mjs` and commit `outputs/` in the same change; treat "is this script in a shipped closure?" as a checklist item. (This branch followed that discipline.)
