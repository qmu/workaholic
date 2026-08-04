---
type: Feedback
title: The heartbeat's guarantee is asserted in one place and relied on in two
kind: concern
source: development
created_at: 2026-08-04T12:34:27+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-heartbeat-s-guarantee-is-asserted
owner: 
mission: []
tickets: [20260804023000-readonly-scripts-commit-git-index.md]
origin_pr: 179
origin_pr_url: https://github.com/qmu/workaholic/pull/179
origin_branch: work-20260804-111346
origin_commit: f964a213
last_seen: 2026-08-04T12:34:27+09:00
---

# The heartbeat's guarantee is asserted in one place and relied on in two

## Description

`commit.sh --allow-empty` is used by the heartbeat and by the resume

## How to Fix

Extend the resumption test to assert its `Resume` commit's file list is
