---
type: Feedback
title: (carried from PR #56) Enforcement reaches consumer repos only after this release
kind: concern
source: development
created_at: 2026-06-27T23:57:36+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: enforcement-reaches-consumer-repos-only-after
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

# (carried from PR #56) Enforcement reaches consumer repos only after this release

## Description

The ticket-structure enforcement hooks live in the workaholic plugin; a consumer repo gains them only once this version is published and the repo updates. Migrated consumers on `autoUpdate: true` pull them post-release, but in-flight branches there can still reintroduce non-canonical paths until then.

## How to Fix

Ship this branch via `/release`; autoUpdate propagates the enforcement to consumers automatically.
