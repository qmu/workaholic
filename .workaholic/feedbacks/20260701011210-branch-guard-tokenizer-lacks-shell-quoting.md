---
type: Feedback
title: Branch-guard tokenizer lacks shell-quoting awareness
kind: concern
source: development
created_at: 2026-07-01T01:12:10+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: branch-guard-tokenizer-lacks-shell-quoting
owner: 
mission: 
tickets: []
origin_pr: 63
origin_pr_url: https://github.com/qmu/workaholic/pull/63
origin_branch: work-20260630-050446
origin_commit: 4ee61c5
last_seen: 2026-07-01T21:16:06+09:00
closed: accepted
---

# Branch-guard tokenizer lacks shell-quoting awareness

## Description

The guard scans the entire command string and cannot tell a real command from text inside an `echo`/quoted argument, so the literal phrase `git branch <word>` inside `echo "…"` still trips it (see [5ed322f](https://github.com/qmu/workaholic/commit/5ed322f) in `plugins/workaholic/hooks/guard-git-branch.sh`). This is inherent to the whitespace tokenizer, which deliberately avoids a full shell parser.

## How to Fix

Agents should avoid embedding `git branch <word>` in echo/log strings; this is guidance, not a code change.
