---
origin_pr: 39
origin_pr_url: https://github.com/qmu/workaholic/pull/39
origin_branch: work-20260417-092936
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
last_seen: 2026-05-19T11:48:42+09:00
first_seen: 2026-05-19T11:48:42+09:00
concern_id: inline-shell-invocations-remain-in-core
severity: moderate
status: resolved
resolved_by_pr: a5c376f
resolved_by_commit: 
---

# Inline shell invocations remain in core:drive

## Description

`core:drive` still calls `ls -1` inline at several points (lines 117, 169, 187, 194 in `plugins/core/skills/drive/SKILL.md`), which violates the repository's Shell Script Principle that multi-step or list-producing shell logic must live in bundled skill scripts rather than inline in markdown.

## How to Fix

Extract the remaining inline invocations into dedicated navigator scripts under the drive skill's `scripts/` directory, and reference them via `${CLAUDE_PLUGIN_ROOT}` so the skill stays compliant with the Shell Script Principle.
