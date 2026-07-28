---
type: Feedback
title: the-drive-skill-still-contains-short
kind: concern
source: development
created_at: 2026-05-19T11:48:42+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-drive-skill-still-contains-short
owner: 
mission: 
tickets: []
origin_pr: 39
origin_pr_url: https://github.com/qmu/workaholic/pull/39
origin_branch: work-20260417-092936
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:42+09:00
closed: resolved
---

- The drive skill still contains short inline `ls -1` and `mv ... && git add ...` invocations migrated verbatim from the navigator that predate the Shell Script Principle (see [a0949ae](https://github.com/qmu/workaholic/commit/a0949ae) in `plugins/core/skills/drive/SKILL.md`)
