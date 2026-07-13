---
origin_pr: 44
origin_pr_url: https://github.com/qmu/workaholic/pull/44
origin_branch: work-20260617-082241
origin_commit: ba49fe6
created_at: 2026-06-17T20:14:03+09:00
last_seen: 2026-06-17T20:14:03+09:00
first_seen: 2026-06-17T20:14:03+09:00
concern_id: references-split-deferred-pending-upstream-clarification
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #42) references/ split deferred pending upstream clarification

## Description

Splitting `drive`/`report` operational detail into sibling `references/` files was scoped out because the `skills` CLI and OpenAI agent SDK docs do not document how a `references/` directory beside `SKILL.md` is loaded.

## How to Fix

Confirm `references/` loading behavior upstream before reopening; once verified, land the split in a follow-up.
