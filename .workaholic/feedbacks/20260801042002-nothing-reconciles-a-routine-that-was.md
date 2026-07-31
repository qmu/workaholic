---
type: Feedback
title: Nothing reconciles a routine that was deleted outside this flow
kind: concern
source: development
created_at: 2026-08-01T04:20:02+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: nothing-reconciles-a-routine-that-was
owner: 
mission: []
tickets: [20260801030421-workaholify-provisions-the-loop-engineering-environment.md]
origin_pr: 138
origin_pr_url: https://github.com/qmu/workaholic/pull/138
origin_branch: work-20260801-033154
origin_commit: 2c2db915
last_seen: 2026-08-01T04:20:02+09:00
---

# Nothing reconciles a routine that was deleted outside this flow

## Description

`RemoteTrigger` has no delete, so this flow can add and refresh but never remove. A routine deleted at claude.ai simply reappears as `missing` on the next survey.

## How to Fix

Correct as-is — the survey reports, the developer decides. Only worth revisiting if deliberate removals become common enough that the repeated `missing` report becomes noise.
