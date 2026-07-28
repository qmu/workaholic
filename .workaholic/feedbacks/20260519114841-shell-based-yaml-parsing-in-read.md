---
type: Feedback
title: shell-based-yaml-parsing-in-read
kind: concern
source: development
created_at: 2026-05-19T11:48:41+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: shell-based-yaml-parsing-in-read
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

- Shell-based YAML parsing in `read-plan.sh` is fragile; the script relies on simple grep/sed patterns for flat frontmatter fields, which may break if users include special characters in the instruction field (see [790c4e5](https://github.com/qmu/workaholic/commit/790c4e5) in `plugins/trippin/skills/trip-protocol/sh/read-plan.sh`)
