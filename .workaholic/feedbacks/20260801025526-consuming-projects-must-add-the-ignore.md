---
type: Feedback
title: Consuming projects must add the ignore entries themselves
kind: concern
source: development
created_at: 2026-08-01T02:55:26+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: consuming-projects-must-add-the-ignore
owner: 
mission: []
tickets: [20260801003034-worktrees-are-never-reclaimed.md]
origin_pr: 132
origin_pr_url: https://github.com/qmu/workaholic/pull/132
origin_branch: work-20260801-023444
origin_commit: d29e07bf
last_seen: 2026-08-01T02:55:26+09:00
---

# Consuming projects must add the ignore entries themselves

## Description

`.worktrees/` and `.publish/` land in any build context, archive, or index rooted at the repository. The scripts add both to `.git/info/exclude`, which covers git and nothing else (`plugins/workaholic/skills/branching/SKILL.md`).

## How to Fix

Documented with the recommended `.dockerignore` entry. `/workaholify` is where an automated check for it would belong if this recurs.
