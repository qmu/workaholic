---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #67) Browser MCP is session-provided and optional

## Description

`/explain`'s PDF export depends on a browser MCP that is session-provided and optional, so the export can be unavailable at runtime (deferred concern `.workaholic/concerns/67-browser-mcp-is-session-provided-and.md`).

## How to Fix

Detect the missing browser MCP and degrade with a clear message or fallback path.
