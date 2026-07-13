---
origin_pr: 41
origin_pr_url: https://github.com/qmu/workaholic/pull/41
origin_branch: work-20260528-091259
origin_commit: b53a3a0
created_at: 2026-05-28T12:02:14+09:00
last_seen: 2026-05-28T12:02:14+09:00
first_seen: 2026-05-28T12:02:14+09:00
concern_id: accepted-cross-agent-coupling
severity: low
status: resolved
disposition: accepted
resolved_by_pr: 
resolved_by_commit: 
---

# Accepted cross-agent coupling

## Description

The new `CLAUDE.md` convention couples `core:ship` to a Claude-specific filename. On non-Claude agents (Codex, OpenCode) without a `CLAUDE.md`, the deploy step skips silently. This is an intentional, accepted consequence of the `CLAUDE.md`-only design and the `find-claude-md.sh` name itself (see [13f365e](https://github.com/qmu/workaholic/commit/13f365e) in `plugins/core/skills/ship/SKILL.md`).

## How to Fix

Document the expected behavior in agent-specific docs so users understand why deploy/verify are skipped on non-Claude platforms when no `CLAUDE.md` exists. Not a bug to fix — a contract to maintain.

## Triage Disposition (work-20260623-181237)

**Accepted — not actionable.** This is a deliberate design boundary (`CLAUDE.md`-only deploy convention), explicitly "a contract to maintain, not a bug." Closed at triage so it stops re-surfacing as open work; archived for audit. Canonical for the duplicate chain `42-carried-from-pr-41-accepted-cross`, `43-…`, `44-…`.
