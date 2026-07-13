---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
superseded_by: carry-cannot-auto-trigger-on-token
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T21:16:06+09:00
concern_id: carry-cannot-auto-trigger-on-token
severity: moderate
status: superseded
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #67) /carry cannot auto-trigger on token exhaustion

## Description

`/carry` cannot auto-trigger on token exhaustion, so a session may run out before handoff state is captured (deferred concern `.workaholic/concerns/67-carry-cannot-auto-trigger-on-token.md`).

## How to Fix

Explore a proactive checkpoint trigger as context nears exhaustion.
