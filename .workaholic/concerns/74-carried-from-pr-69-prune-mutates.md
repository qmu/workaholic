---
type: Concern
origin_pr: 74
origin_pr_url: https://github.com/qmu/workaholic/pull/74
origin_branch: work-20260701-221800
origin_commit: f25dffa
created_at: 2026-07-06T11:31:52+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #69) Prune mutates the user's `refs/remotes/` state

## Description

The `scan-window.sh --prune` flag passes `--prune` to `git fetch`, which modifies the local refs/remotes/ cache by deleting stale branches. A developer running catch/report with --prune cleans up remote state as a side effect (see `plugins/workaholic/skills/catch/scripts/scan-window.sh`).

## How to Fix

Make `--prune` more explicit (e.g., `--prune-refs`) or off by default, and document the mutation; or store the state change in a separate operation so the main flow is read-only.
