---
origin_pr: 63
origin_pr_url: https://github.com/qmu/workaholic/pull/63
origin_branch: work-20260630-050446
origin_commit: 4ee61c5
created_at: 2026-07-01T01:12:10+09:00
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T01:12:10+09:00
concern_id: catch-generation-style-is-an-explicit
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# `/catch` generation-style is an explicit guess

## Description

The generation-style field is inferred from commit-timestamp shape and is framed as a guess, not fact (see [d9a695b](https://github.com/qmu/workaholic/commit/d9a695b) in `plugins/workaholic/skills/catch/SKILL.md`). The "looks like…" framing must be preserved when rendering.

## How to Fix

Keep the explicit-guess wording in the report template so the field is never read as authoritative.
