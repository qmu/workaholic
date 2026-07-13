---
origin_pr: 60
origin_pr_url: https://github.com/qmu/workaholic/pull/60
origin_branch: work-20260630-011820
origin_commit: 7a2c78d
created_at: 2026-06-30T02:27:29+09:00
last_seen: 2026-06-30T02:27:29+09:00
first_seen: 2026-06-30T02:27:29+09:00
concern_id: by-developer-axis-joins-on-commit
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# By-developer axis joins on commit email + ticket-author frontmatter

## Description

`scan-window.sh` groups commits by author email and joins ticket frontmatter author to build the roster. This works uniformly across commits, todo, and archive, but the scope set (`todo`/`archive`/`icebox` for tickets, `stories/` for narrative) does not yet specially attribute icebox/abandoned work per developer (discovered during `/catch` implementation, `plugins/workaholic/skills/catch/scripts/scan-window.sh`).

## How to Fix

Document the current scope reach; extend the scope set if per-developer icebox/abandoned reporting becomes load-bearing.
