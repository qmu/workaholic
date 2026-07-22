---
type: Concern
concern_id: unreachable-configured-origin-now-hard-fails
mission: []
owner: 
tickets: [20260722200001-fetch-origin-before-resolving-mission-worktree-base.md]
origin_pr: 95
origin_pr_url: https://github.com/qmu/workaholic/pull/95
origin_branch: work-20260723-000846
origin_commit: 2d6215be
created_at: 2026-07-23T02:27:01+09:00
first_seen: 2026-07-23T02:27:01+09:00
last_seen: 2026-07-23T02:27:01+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# Unreachable configured origin now hard-fails mission-worktree creation

## Description

When origin is configured but unreachable, `create-mission-worktree.sh` hard-fails with a JSON error, giving no offline escape hatch for a developer working offline with a remote configured (see [dd5335a1](https://github.com/qmu/workaholic/commit/dd5335a1) in `plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh`). The ticket explicitly mandates fail-loud over silent-stale, but this is a real usability trade-off.

## How to Fix

If this bites in practice, relax to a loud local fallback (stderr note + proceed) rather than a hard failure, which still satisfies the quality gate's "without loudly reporting why" clause.
