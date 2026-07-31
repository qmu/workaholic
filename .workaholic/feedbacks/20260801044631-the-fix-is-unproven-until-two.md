---
type: Feedback
title: The fix is unproven until two PRs merge close together
kind: concern
source: development
created_at: 2026-08-01T04:46:31+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-fix-is-unproven-until-two
owner: 
mission: []
tickets: [20260801042354-merged-pr-routine-announces-every-recent-merge.md]
origin_pr: 143
origin_pr_url: https://github.com/qmu/workaholic/pull/143
origin_branch: work-20260801-042633
origin_commit: 42fafffd
last_seen: 2026-08-01T04:46:31+09:00
---

# The fix is unproven until two PRs merge close together

## Description

The defect lives in a model's reading of a prompt. The suite asserts the instruction is present and unambiguous; it cannot assert obedience. The acceptance criterion — two PRs merged within a minute producing exactly two messages — has not yet been run.

## How to Fix

Merge two prepared PRs in quick succession and count the messages in `#dev-workaholic`. Re-run after any later edit to these prompts.
