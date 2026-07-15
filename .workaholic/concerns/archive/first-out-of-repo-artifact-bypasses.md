---
origin_pr: 67
origin_pr_url: https://github.com/qmu/workaholic/pull/67
origin_branch: work-20260701-093015
origin_commit: 21a5f49
created_at: 2026-07-01T13:35:59+09:00
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T13:35:59+09:00
concern_id: first-out-of-repo-artifact-bypasses
severity: moderate
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: The /explain export is a by-design, consent-gated developer artifact, and its safeguards are all present (symmetric no-default-yes consent, fail-safe writability halt, never touching config/profile paths). The confinement guard cannot close it: a PreToolUse hook sees only tool_input.file_path and the PDF is written by the browser over MCP, not by a Write. Addressed instead by staging /explain's HTML in-repo this session.
closed_at: 2026-07-15T19:50:28+09:00
---

# First out-of-repo artifact bypasses the layout hook

## Description

`/explain`'s PDF lands outside `.workaholic/`, so it sits outside the layout-validation machinery (`validate-ticket.sh` matches only `*.workaholic/*`); the only guardrails are the Home consent gate and the resolver's writability check (see [2e5ef4f](https://github.com/qmu/workaholic/commit/2e5ef4f) in `plugins/workaholic/skills/explain/scripts/resolve-export-path.sh`).

## How to Fix

Keep the consent gate symmetric and the resolver's fail-safe writability check in place; ensure the resolver never touches config/profile paths or escalates privilege.
