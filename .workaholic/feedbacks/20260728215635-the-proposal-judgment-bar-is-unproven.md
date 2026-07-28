---
type: Feedback
title: The proposal judgment bar is unproven against live feedback
kind: concern
source: development
created_at: 2026-07-28T21:56:35+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-proposal-judgment-bar-is-unproven
owner: a@qmu.jp
mission: [loop-engineering-proposal-loop]
tickets: [20260728210301-merge-concern-corpus-into-feedback-stream.md, 20260728210302-add-proposal-batch-command-and-skill.md, 20260728210303-add-slack-notifier-and-proposal-runbook.md]
origin_pr: 99
origin_pr_url: https://github.com/qmu/workaholic/pull/99
origin_branch: work-20260728-210259
origin_commit: 773ff9db
last_seen: 2026-07-28T21:56:35+09:00
---

# The proposal judgment bar is unproven against live feedback

## Description

`/propose`'s propose-or-stay-silent judgment is written policy but has never run against real accumulated feedback; the first cron cycles could over-propose (spamming the channel) or stay silent on direction a human expected to be picked up (see [70bea0a4](https://github.com/qmu/workaholic/commit/70bea0a4) in `plugins/workaholic/skills/propose/SKILL.md`)

## How to Fix

Observe the first live cycles against the runbook's ledger (`Propose mission` commits vs the feedback that arrived); tune the bar's wording in the skill from real misses, and treat every miss as a feedback entry of its own.
