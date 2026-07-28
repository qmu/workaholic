---
type: Feedback
title: (carried from PR #56) Two enforcement layers encode one rule (drift risk)
kind: concern
source: development
created_at: 2026-06-27T23:57:36+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: two-enforcement-layers-encode-one-rule
owner: 
mission: 
tickets: []
origin_pr: 58
origin_pr_url: https://github.com/qmu/workaholic/pull/58
origin_branch: work-20260627-153246
origin_commit: 32110a0
last_seen: 2026-06-27T23:57:36+09:00
closed: superseded
---

# (carried from PR #56) Two enforcement layers encode one rule (drift risk)

## Description

The canonical-path rule lives in both `validate-ticket.sh` (PostToolUse) and `guard-ticket-structure.sh` (PreToolUse). Converting `validate-ticket.sh` to POSIX here did not consolidate them, so future edits must change both or they will disagree.

## How to Fix

Keep the path-shape rules equivalent; extract a shared helper if a third consumer appears.
