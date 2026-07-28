---
type: Feedback
title: (carried from PR #41) Script rename requires stale artifact cleanup
kind: concern
source: development
created_at: 2026-06-17T01:51:15+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: script-rename-requires-stale-artifact-cleanup
owner: 
mission: 
tickets: []
origin_pr: 43
origin_pr_url: https://github.com/qmu/workaholic/pull/43
origin_branch: work-20260617-000311
origin_commit: 1ed7fbb
last_seen: 2026-06-17T01:51:15+09:00
closed: resolved
---

# (carried from PR #41) Script rename requires stale artifact cleanup

## Description

`build.mjs` still has no orphan-cleanup pass; renames rely on manual `git mv` + freshness CI to catch leftovers (see `.workaholic/concerns/41-script-rename-requires-stale-artifact-cleanup.md`).

## How to Fix

Add a cleanup pass to `build.mjs` that removes orphaned generated artifacts before reassembly.
