---
origin_pr: 60
origin_pr_url: https://github.com/qmu/workaholic/pull/60
origin_branch: work-20260630-011820
origin_commit: 7a2c78d
created_at: 2026-06-30T02:27:29+09:00
last_seen: 2026-07-16T12:06:03+09:00
first_seen: 2026-06-30T02:27:29+09:00
concern_id: by-developer-axis-joins-on-commit
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# By-developer axis joins on commit email + ticket-author frontmatter

## Description

`scan-window.sh` builds its per-developer roster from `todo`, `archive` and `icebox`, but not `abandoned` — which `/drive` actively writes to, and which holds two real tickets today, invisible to `/catch` and attributable to nobody (see `plugins/workaholic/skills/catch/scripts/scan-window.sh`).

## How to Fix

Add `abandoned` to the TDIRS loop plus the scope/case mapping.

