---
origin_pr: 63
origin_pr_url: https://github.com/qmu/workaholic/pull/63
origin_branch: work-20260630-050446
origin_commit: 4ee61c5
created_at: 2026-07-01T01:12:10+09:00
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T01:12:10+09:00
concern_id: branch-guard-tokenizer-lacks-shell-quoting
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Branch-guard tokenizer lacks shell-quoting awareness

## Description

The guard scans the entire command string and cannot tell a real command from text inside an `echo`/quoted argument, so the literal phrase `git branch <word>` inside `echo "…"` still trips it (see [5ed322f](https://github.com/qmu/workaholic/commit/5ed322f) in `plugins/workaholic/hooks/guard-git-branch.sh`). This is inherent to the whitespace tokenizer, which deliberately avoids a full shell parser.

## How to Fix

Agents should avoid embedding `git branch <word>` in echo/log strings; this is guidance, not a code change.
