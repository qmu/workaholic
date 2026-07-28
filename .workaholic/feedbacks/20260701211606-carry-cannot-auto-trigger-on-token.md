---
type: Feedback
title: (carried from PR #67) /carry cannot auto-trigger on token exhaustion
kind: concern
source: development
created_at: 2026-07-01T21:16:06+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: carry-cannot-auto-trigger-on-token
owner: 
mission: 
tickets: []
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
last_seen: 2026-07-01T21:16:06+09:00
closed: superseded
---

# (carried from PR #67) /carry cannot auto-trigger on token exhaustion

## Description

`/carry` cannot auto-trigger on token exhaustion, so a session may run out before handoff state is captured (deferred concern `.workaholic/concerns/67-carry-cannot-auto-trigger-on-token.md`).

## How to Fix

Explore a proactive checkpoint trigger as context nears exhaustion.
