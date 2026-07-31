---
type: Feedback
title: Only this repository is bootstrapped
kind: concern
source: development
created_at: 2026-08-01T04:20:02+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: only-this-repository-is-bootstrapped
owner: 
mission: []
tickets: [20260801030421-workaholify-provisions-the-loop-engineering-environment.md]
origin_pr: 138
origin_pr_url: https://github.com/qmu/workaholic/pull/138
origin_branch: work-20260801-033154
origin_commit: 2c2db915
last_seen: 2026-08-01T04:20:02+09:00
---

# Only this repository is bootstrapped

## Description

The check and the canonical hook now exist, and workaholic itself is wired, but every other repository carrying a workaholic routine is presumably still unbootstrapped — its routines firing hourly and doing nothing.

## How to Fix

Run `/workaholify` in each. The check is per-repository by design; nothing here reaches into another repository, which is the confinement rule.
