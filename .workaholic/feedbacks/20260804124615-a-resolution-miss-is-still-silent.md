---
type: Feedback
title: A resolution miss is still silent, and still becomes a takeover
kind: concern
source: development
created_at: 2026-08-04T12:46:15+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-resolution-miss-is-still-silent
owner: 
mission: []
tickets: [20260804023100-claim-survey-reads-wrong-coordinate.md]
origin_pr: 178
origin_pr_url: https://github.com/qmu/workaholic/pull/178
origin_branch: work-20260804-105730
origin_commit: 6264039f
last_seen: 2026-08-04T12:46:15+09:00
---

# A resolution miss is still silent, and still becomes a takeover

## Description

The fallback removes the known way an artifact list goes empty, but not

## How to Fix

Carry an explicit `unresolved` count on the claim row and let
