---
type: Feedback
title: The ASCII 6-word truncation collision remains by design
kind: concern
source: development
created_at: 2026-08-03T22:04:38+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-ascii-6-word-truncation-collision
owner: 
mission: 
tickets: [20260801193000-fix-extract-concerns-japanese-titles.md]
origin_pr: 170
origin_pr_url: https://github.com/qmu/workaholic/pull/170
origin_branch: work-20260803-210404
origin_commit: ebf38dad
last_seen: 2026-08-03T22:04:38+09:00
---

# The ASCII 6-word truncation collision remains by design

## Description

The measured 6-word/60-char truncation collision between distinct ASCII titles (recorded in the stream, 2026-07-16) is deliberately untouched: only titles the word slug cannot represent switch to the hash, so the fix cannot re-key any existing ASCII-titled concern (`plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh`).

## How to Fix

Already tracked as its own open concern; a hash suffix on truncated ASCII slugs is the sketched fix there and should be judged on its own id-stability cost.
