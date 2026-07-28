---
type: Feedback
title: (carried from PR #67) Browser MCP is session-provided and optional
kind: concern
source: development
created_at: 2026-07-01T21:16:06+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: browser-mcp-is-session-provided-and
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

# (carried from PR #67) Browser MCP is session-provided and optional

## Description

`/explain`'s PDF export depends on a browser MCP that is session-provided and optional, so the export can be unavailable at runtime (deferred concern `.workaholic/concerns/67-browser-mcp-is-session-provided-and.md`).

## How to Fix

Detect the missing browser MCP and degrade with a clear message or fallback path.
