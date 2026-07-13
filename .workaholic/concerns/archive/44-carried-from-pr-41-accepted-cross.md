---
origin_pr: 44
origin_pr_url: https://github.com/qmu/workaholic/pull/44
origin_branch: work-20260617-082241
origin_commit: ba49fe6
created_at: 2026-06-17T20:14:03+09:00
last_seen: 2026-06-17T20:14:03+09:00
first_seen: 2026-06-17T20:14:03+09:00
concern_id: accepted-cross-agent-coupling
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #41) Accepted cross-agent coupling

## Description

The `core:ship` skill couples to `CLAUDE.md`, a Claude-specific filename. On non-Claude agents without a `CLAUDE.md`, the deploy step skips silently. This is an intentional, accepted contract (see [13f365e](https://github.com/qmu/workaholic/commit/13f365e)).

## How to Fix

Document the expected behavior in agent-specific docs so users understand why deploy/verify are skipped on non-Claude platforms. Not a bug — a contract to maintain.
