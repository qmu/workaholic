---
type: Feedback
title: The adjacency rule encodes a judgement the ticket did not specify
kind: concern
source: development
created_at: 2026-08-04T12:37:29+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-adjacency-rule-encodes-a-judgement
owner: 
mission: []
tickets: [20260802093000-request-backstop-substring-false-positive.md]
origin_pr: 180
origin_pr_url: https://github.com/qmu/workaholic/pull/180
origin_branch: work-20260804-112404
origin_commit: 6db80985
last_seen: 2026-08-04T12:37:29+09:00
---

# The adjacency rule encodes a judgement the ticket did not specify

## Description

The ticket asked that the bare name not match when adjacent to `-`, `_`

## How to Fix

Nothing to change; the case is asserted in the fixtures and recorded in
