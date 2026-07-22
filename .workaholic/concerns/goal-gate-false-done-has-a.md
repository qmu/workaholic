---
type: Concern
concern_id: goal-gate-false-done-has-a
mission: []
tickets: [20260719000021-goal-gate-satisfied-by-self-emitted-token-false-done.md, 20260719081347-monitor-front-loads-decisions-then-runs-unattended.md, 20260719224444-mission-reorganize-carry-doctrine.md, 20260720153729-guard-working-directory-opt-in-blocking.md, 20260720154514-request-single-confirmation.md, 20260720162807-interaction-necessity-guideline.md]
origin_pr: 91
origin_pr_url: https://github.com/qmu/workaholic/pull/91
origin_branch: work-20260719-075112
origin_commit: 01fa6815
created_at: 2026-07-21T11:26:01+09:00
first_seen: 2026-07-21T11:26:01+09:00
last_seen: 2026-07-23T02:27:01+09:00
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Goal-gate false-done has a harness-side residual

## Description

The `/goal <token>` Stop hook is satisfied the moment the agent emits a token, even when the underlying objective is materially incomplete. The repo-side half has shipped; the harness-side corroboration remains and is outside workaholic's repo-side reach. (See PR #91)

## How to Fix

Raise token-vs-observable-state Stop-gate corroboration with the Claude Code harness; workaholic has no further repo-side actionable work.

