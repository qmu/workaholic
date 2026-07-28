---
type: Feedback
title: the-archive-sh-script-uses-git
kind: concern
source: development
created_at: 2026-05-19T11:48:40+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-archive-sh-script-uses-git
owner: 
mission: 
tickets: []
origin_pr: 26
origin_pr_url: https://github.com/qmu/workaholic/pull/26
origin_branch: drive-20260213-131416
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:40+09:00
closed: resolved
---

- The `archive.sh` script uses `git add -A` which stages everything including unrelated changes; while this is intentional for catching both deletion and addition paths, it could inadvertently stage work-in-progress files (see [9e54500](https://github.com/qmu/workaholic/commit/9e54500) in `plugins/core/skills/archive-ticket/SKILL.md`)
