---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
superseded_by: stale-plugin-install-is-indistinguishable-from
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T21:16:06+09:00
concern_id: stale-plugin-install-is-indistinguishable-from
severity: moderate
status: superseded
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #63) Stale plugin install is indistinguishable from a broken hook

## Description

A stale plugin install presents the same symptoms as a genuinely broken hook, making diagnosis ambiguous (deferred concern `.workaholic/concerns/63-stale-plugin-install-is-indistinguishable-from.md`).

## How to Fix

Emit a version/identity signal from hooks so a stale install is distinguishable from a real failure.
