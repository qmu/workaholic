---
type: Feedback
title: Release workflow divergence
kind: concern
source: development
created_at: 2026-06-16T08:57:05+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: release-workflow-divergence
owner: 
mission: 
tickets: []
origin_pr: 42
origin_pr_url: https://github.com/qmu/workaholic/pull/42
origin_branch: work-20260528-122941
origin_commit: 0915802
last_seen: 2026-06-16T08:57:05+09:00
closed: resolved
resolved_by_pr: 6bb8db0
---

# Release workflow divergence

## Description

`.claude/commands/release.md` predates the current three-plugin layout. It references the obsolete `tdd` plugin, omits `standards`/`work`, and lacks the version-sync steps this branch relies on (four `plugins[].version` entries, the standards `.codex-plugin/plugin.json`, and dist regeneration). A future `/release` run could silently miss version files and recreate drift (see commit 665ee42, `CLAUDE.md` Version Management).

## How to Fix

Open a follow-up ticket to align `release.md` with the version-bump procedure now documented in `CLAUDE.md`, so human-and-AI release runs converge.
