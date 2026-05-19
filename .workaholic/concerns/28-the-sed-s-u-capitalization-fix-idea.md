---
kind: idea
origin_pr: 28
origin_pr_url: https://github.com/qmu/workaholic/pull/28
origin_branch: drive-20260310-220224
origin_commit: cc5de17
created_at: 2026-05-19T11:48:40+09:00
status: active
resolved_by_pr:
resolved_by_commit:
paired_slug:
housekeeping_ticket_emitted: false
---

- The `sed 's/./\U&/'` capitalization fix uses a GNU sed extension; macOS compatibility would require an alternative approach if the plugin is ever used on macOS environments (see [84b6b2a](https://github.com/qmu/workaholic/commit/84b6b2a) in `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)
