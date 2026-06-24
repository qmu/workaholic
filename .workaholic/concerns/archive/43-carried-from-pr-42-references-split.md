---
origin_pr: 43
origin_pr_url: https://github.com/qmu/workaholic/pull/43
origin_branch: work-20260617-000311
origin_commit: 1ed7fbb
created_at: 2026-06-17T01:51:15+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #42) References split deferred pending upstream clarification

## Description

The `references/` skill split remains deferred pending upstream `skills` CLI / agent SDK clarification on how a `references/` dir beside `SKILL.md` is loaded (see `.workaholic/concerns/42-references-split-deferred-pending-upstream-clarification.md`).

## How to Fix

Confirm the loading behavior upstream, then land the split in a follow-up.
