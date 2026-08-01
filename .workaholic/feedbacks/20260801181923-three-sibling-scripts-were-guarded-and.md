---
type: Feedback
title: Three sibling scripts were guarded and three were not, with nothing to keep them aligned
kind: concern
source: development
created_at: 2026-08-01T18:19:23+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: three-sibling-scripts-were-guarded-and
owner: 
mission: 
tickets: [20260731220639-gh-is-absent-in-the-cloud-runner.md]
origin_pr: 158
origin_pr_url: https://github.com/qmu/workaholic/pull/158
origin_branch: work-20260801-134910
origin_commit: 43c042a1
last_seen: 2026-08-01T18:19:23+09:00
---

# Three sibling scripts were guarded and three were not, with nothing to keep them aligned

## Description

The split existed because nothing checks that every `gh` caller guards. A seventh caller added tomorrow would be unguarded by default, and the same exit-127-after-push failure returns (`plugins/workaholic/skills/`).

## How to Fix

A lint over the plugin's scripts asserting that any file invoking `gh` also contains a `command -v gh` guard — the same shape as the existing `posix-lint.sh`, which already walks every script.
