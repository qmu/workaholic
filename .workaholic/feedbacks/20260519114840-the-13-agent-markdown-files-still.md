---
type: Feedback
title: the-13-agent-markdown-files-still
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-13-agent-markdown-files-still
owner: 
mission: 
tickets: []
origin_pr: 26
origin_pr_url: https://github.com/qmu/workaholic/pull/26
origin_branch: drive-20260213-131416
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
resolved_by_pr: a0949ae
---

- The 13 agent markdown files still use "Role and Responsibility" in natural language, which is slightly redundant under the new structure where Role contains Responsibility; this was left as-is since it remains semantically valid (see [5c99fe9](https://github.com/qmu/workaholic/commit/5c99fe9) in `plugins/core/agents/`)
