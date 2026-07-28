---
type: Feedback
title: (carried from PR #63) Stale plugin install is indistinguishable from a broken hook
kind: concern
source: development
created_at: 2026-07-01T21:16:06+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: stale-plugin-install-is-indistinguishable-from
owner: 
mission: 
tickets: []
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
last_seen: 2026-07-01T21:16:06+09:00
closed: superseded
---

# (carried from PR #63) Stale plugin install is indistinguishable from a broken hook

## Description

A stale plugin install presents the same symptoms as a genuinely broken hook, making diagnosis ambiguous (deferred concern `.workaholic/concerns/63-stale-plugin-install-is-indistinguishable-from.md`).

## How to Fix

Emit a version/identity signal from hooks so a stale install is distinguishable from a real failure.
