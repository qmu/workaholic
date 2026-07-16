---
origin_pr: 56
origin_pr_url: https://github.com/qmu/workaholic/pull/56
origin_branch: work-20260624-140219
origin_commit: e78465d
created_at: 2026-06-24T21:39:11+09:00
last_seen: 2026-07-09T03:28:39+09:00
first_seen: 2026-06-24T21:39:11+09:00
concern_id: two-enforcement-layers-encode-one-rule
severity: moderate
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: The two layers deliberately cover different tool surfaces (PostToolUse Write|Edit vs PreToolUse Bash) and stay equivalent; helper extraction is deferred until a third consumer appears, per the concern's own fix.
closed_at: 2026-07-16T17:06:05+09:00
---

# Two enforcement layers encode one rule (drift risk)

## Description

The canonical-path rule now lives in both `validate-ticket.sh` (bash, PostToolUse) and `guard-ticket-structure.sh` (POSIX sh, PreToolUse). Future edits must change both or they will disagree.

## How to Fix

Keep the path-shape rules equivalent; consider extracting a shared helper if a third consumer appears.
