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
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Filed already-accepted: the guess-framing the concern asked to preserve is in place at catch/SKILL.md:106, :110 and :216 ('phrase it as an inference, never as asserted fact'). The inference is by design and cannot be made factual.
closed_at: 2026-07-15T19:50:28+09:00
---

# `/catch` generation-style is an explicit guess

## Description

The generation-style field is inferred from commit-timestamp shape and is framed as a guess, not fact (see [d9a695b](https://github.com/qmu/workaholic/commit/d9a695b) in `plugins/workaholic/skills/catch/SKILL.md`). The "looks like…" framing must be preserved when rendering.

## How to Fix

Keep the explicit-guess wording in the report template so the field is never read as authoritative.
