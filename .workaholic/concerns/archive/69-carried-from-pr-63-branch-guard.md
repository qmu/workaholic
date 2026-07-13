---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
superseded_by: branch-guard-tokenizer-lacks-shell-quoting
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T21:16:06+09:00
concern_id: branch-guard-tokenizer-lacks-shell-quoting
severity: moderate
status: superseded
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #63) Branch-guard tokenizer lacks shell quoting

## Description

The branch-guard tokenizer does not handle shell quoting, so a quoted/escaped branch-creation command could evade or misparse the gate (deferred concern `.workaholic/concerns/63-branch-guard-tokenizer-lacks-shell-quoting.md`).

## How to Fix

Use a quoting-aware tokenizer (or a stricter parse) in the branch guard.
