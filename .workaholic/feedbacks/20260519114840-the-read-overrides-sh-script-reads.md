---
type: Feedback
title: the-read-overrides-sh-script-reads
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-read-overrides-sh-script-reads
owner: 
mission: 
tickets: []
origin_pr: 22
origin_pr_url: https://github.com/qmu/workaholic/pull/22
origin_branch: drive-20260205-195920
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
resolved_by_pr: d4352d5
---

- The `read-overrides.sh` script reads arbitrary CLAUDE.md content from target repositories, which may contain unexpected directives (see [5b2b024](https://github.com/qmu/workaholic/commit/5b2b024) in `plugins/core/skills/analyze-viewpoint/sh/read-overrides.sh`)
