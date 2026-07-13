---
type: Concern
mission: 
tickets: [20260706182653-push-deferred-concerns-in-ship.md, 20260706203044-mission-artifact-type-and-command.md, 20260706203045-mission-frontmatter-linkage.md, 20260706203046-mission-progress-and-changelog-automation.md, 20260707023034-fix-codex-hooks-json-parse-error.md]
origin_pr: 77
origin_pr_url: https://github.com/qmu/workaholic/pull/77
origin_branch: work-20260706-182705
origin_commit: 1f2d43e
created_at: 2026-07-07T04:09:44+09:00
last_seen: 2026-07-09T03:28:39+09:00
first_seen: 2026-07-07T04:09:44+09:00
concern_id: codex-hook-runtime-behavior-remains-unproven
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Codex hook runtime behavior remains unproven

## Description

This branch fixes the Codex parse failure for `hooks/hooks.json`, but it does not prove what Codex will do with Claude-only hook entries that reference `${CLAUDE_PLUGIN_ROOT}` and Claude event names after parsing succeeds (see [6e69651](https://github.com/qmu/workaholic/commit/6e69651) in `plugins/workaholic/hooks/hooks.json`).

## How to Fix

During ship verification, re-add or refresh the workaholic Codex plugin cache and confirm Codex loads the plugin cleanly; if Codex then attempts to run Claude-only hooks, split or isolate Codex-visible hook config in a follow-up.
