---
origin_pr: 67
origin_pr_url: https://github.com/qmu/workaholic/pull/67
origin_branch: work-20260701-093015
origin_commit: 21a5f49
created_at: 2026-07-01T13:35:59+09:00
severity: moderate
status: resolved
resolved_by_pr: 6601029
resolved_by_commit: 
---

# Prompt phrasing is prose, not machine-checked

## Description

The convention that every `AskUserQuestion` carries the `[project]` prefix lives only in per-skill "User interaction" prose; a future prompt could omit it with no static enforcement (see [fc163bd](https://github.com/qmu/workaholic/commit/fc163bd) in `plugins/workaholic/skills/drive/SKILL.md`).

## How to Fix

Add a coverage check to `scripts/build-plugins/verify.mjs` that scans skills for `AskUserQuestion` sites and validates the `[project]` prefix, or rely on code-review discipline anchored in the documented convention.
