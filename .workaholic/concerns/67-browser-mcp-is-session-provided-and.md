---
origin_pr: 67
origin_pr_url: https://github.com/qmu/workaholic/pull/67
origin_branch: work-20260701-093015
origin_commit: 21a5f49
created_at: 2026-07-01T13:35:59+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# Browser MCP is session-provided and not guaranteed

## Description

`/explain` depends on the Playwright plugin or Chrome DevTools MCP (the plugin declares no `.mcp.json`), which may be absent; the capability check is model-level (not shell-scriptable) and degradation saves the HTML but halts the PDF (see [2e5ef4f](https://github.com/qmu/workaholic/commit/2e5ef4f) in `plugins/workaholic/skills/explain/SKILL.md`).

## How to Fix

Keep the no-MCP halt message actionable, naming the two MCPs to enable; document them in `/explain` help.
