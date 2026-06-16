---
origin_pr: 43
origin_pr_url: https://github.com/qmu/workaholic/pull/43
origin_branch: work-20260617-000311
origin_commit: 1ed7fbb
created_at: 2026-06-17T01:51:15+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #42) Release workflow divergence

## Description

`.claude/commands/release.md` is stale and now more divergent — it still references `plugins/core` (which no longer exists after the merge) and predates the consolidated version-file set (see `.workaholic/concerns/42-release-workflow-divergence.md`).

## How to Fix

Rewrite `/release` to the merged single-plugin version-bump procedure (one `plugin.json` + `.codex-plugin` + `marketplace.json`), or retire it in favour of the documented CLAUDE.md flow.
