---
type: Feedback
title: the-sed-s-u-capitalization-fix
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-sed-s-u-capitalization-fix
owner: 
mission: 
tickets: []
origin_pr: 28
origin_pr_url: https://github.com/qmu/workaholic/pull/28
origin_branch: drive-20260310-220224
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
resolved_by_pr: 30d86cb
---

- The `sed 's/./\U&/'` capitalization fix uses a GNU sed extension; macOS compatibility would require an alternative approach if the plugin is ever used on macOS environments (see [84b6b2a](https://github.com/qmu/workaholic/commit/84b6b2a) in `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)
