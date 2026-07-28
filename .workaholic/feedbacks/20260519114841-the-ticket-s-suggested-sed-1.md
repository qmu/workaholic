---
type: Feedback
title: the-ticket-s-suggested-sed-1
kind: concern
source: development
created_at: 2026-05-19T11:48:41+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-ticket-s-suggested-sed-1
owner: 
mission: 
tickets: []
origin_pr: 30
origin_pr_url: https://github.com/qmu/workaholic/pull/30
origin_branch: drive-20260312-102414
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:41+09:00
closed: resolved
---

- The ticket's suggested `sed '1{/^---$/,/^---$/d}'` pattern for frontmatter stripping was discovered to be incorrect at implementation time; the actual implementation uses an awk one-liner instead (see [9cab3fd](https://github.com/qmu/workaholic/commit/9cab3fd) in `plugins/drivin/skills/create-pr/sh/strip-frontmatter.sh`)
