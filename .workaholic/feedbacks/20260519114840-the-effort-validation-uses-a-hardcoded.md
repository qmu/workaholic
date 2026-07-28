---
type: Feedback
title: the-effort-validation-uses-a-hardcoded
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-effort-validation-uses-a-hardcoded
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

- The effort validation uses a hardcoded allowlist in `update.sh`; if new effort values are added, both the script and the hook must be updated in sync (see [ae47bf6](https://github.com/qmu/workaholic/commit/ae47bf6) in `plugins/core/skills/update-ticket-frontmatter/sh/update.sh`)
