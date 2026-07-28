---
type: Feedback
title: /commit is an escape hatch that can invite non-ticketed commits
kind: concern
source: development
created_at: 2026-06-29T13:18:46+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: commit-is-an-escape-hatch-that
owner: 
mission: 
tickets: []
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
last_seen: 2026-06-30T02:27:29+09:00
closed: accepted
---

# /commit is an escape hatch that can invite non-ticketed commits

## Description

The new `/commit` command provides a sanctioned path for ad-hoc commits, but by existing it can normalize committing outside the ticketed `/drive` flow (see [a62d99c](https://github.com/qmu/workaholic/commit/a62d99c) in `plugins/workaholic/commands/commit.md`). It is still strictly better than free-handed `git commit` because both the command and the gate preserve the message policy.

## How to Fix

Keep the command copy steering users to `/drive` for ticketed work and framing `/commit` as for small/explicit non-ticketed changes; revisit if commit history shows `/commit` displacing ticketed development.
