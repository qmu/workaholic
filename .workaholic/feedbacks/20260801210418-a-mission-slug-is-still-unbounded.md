---
type: Feedback
title: A mission slug is still unbounded, and other consumers may have their own limits
kind: concern
source: development
created_at: 2026-08-01T21:04:18+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: a-mission-slug-is-still-unbounded
owner: 
mission: 
tickets: [20260801205101-a-long-mission-slug-cannot-be-claimed.md]
origin_pr: 166
origin_pr_url: https://github.com/qmu/workaholic/pull/166
origin_branch: work-20260801-205224
origin_commit: 22220a7b
last_seen: 2026-08-01T21:04:18+09:00
---

# A mission slug is still unbounded, and other consumers may have their own limits

## Description

The fix removes the subject's length dependency but bounds nothing, which is deliberate. Any *other* consumer that embeds a slug in a length-limited field would hit the same wall, and none is currently known (`plugins/workaholic/skills/mission/scripts/slug.sh`).

## How to Fix

Nothing now. If a second such consumer appears, bound the slug at `slug.sh` rather than teaching each consumer to truncate.
