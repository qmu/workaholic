---
origin_pr: 67
origin_pr_url: https://github.com/qmu/workaholic/pull/67
origin_branch: work-20260701-093015
origin_commit: 21a5f49
created_at: 2026-07-01T13:35:59+09:00
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T13:35:59+09:00
concern_id: carry-cannot-auto-trigger-on-token
severity: moderate
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Blocked on a platform capability, not repo code: no hook or setting can read the remaining context budget. Documented in commands/carry.md as the reason /carry is an explicit, user-invoked checkpoint. Re-open if Claude Code ever exposes a context-budget signal.
closed_at: 2026-07-15T19:50:28+09:00
---

# /carry cannot auto-trigger on token exhaustion

## Description

No programmatic token-budget signal is available to commands or hooks (a `PreCompact` hook has no model access), so `/carry` must be user-invoked (see [386af5e](https://github.com/qmu/workaholic/commit/386af5e) in `plugins/workaholic/commands/carry.md`).

## How to Fix

If Claude Code later exposes a context-budget signal or a model-capable pre-compaction hook, a non-blocking `PreCompact` nudge ("consider running /carry") becomes possible; until then it stays explicit.
