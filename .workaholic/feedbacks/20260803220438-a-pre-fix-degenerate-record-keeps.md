---
type: Feedback
title: A pre-fix degenerate record keeps its degenerate id
kind: concern
source: development
created_at: 2026-08-03T22:04:38+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: a-pre-fix-degenerate-record-keeps
owner: 
mission: 
tickets: [20260801193000-fix-extract-concerns-japanese-titles.md]
origin_pr: 170
origin_pr_url: https://github.com/qmu/workaholic/pull/170
origin_branch: work-20260803-210404
origin_commit: ebf38dad
last_seen: 2026-08-03T22:04:38+09:00
---

# A pre-fix degenerate record keeps its degenerate id

## Description

Ids are permanent keys, so a record minted under the old rule (e.g. a literal `concern_id: concern`) is never rewritten; the same logical concern re-extracted now mints a fresh `c-<hash>` id beside it, so the two records are not linked. The one known case was already worked around manually with explicit ASCII ids (`plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh`).

## How to Fix

Nothing mechanical — the reader's judgment over the stream covers a duplicate pair, and no migration should re-key permanent ids.
