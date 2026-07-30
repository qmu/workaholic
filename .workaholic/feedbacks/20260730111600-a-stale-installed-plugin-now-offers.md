---
type: Feedback
title: A stale installed plugin now offers a command name that no longer exists in source
kind: concern
source: development
created_at: 2026-07-30T11:16:00+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-stale-installed-plugin-now-offers
owner: 
mission: []
tickets: []
origin_pr: 103
origin_pr_url: https://github.com/qmu/workaholic/pull/103
origin_branch: work-20260729-193859
origin_commit: 2e7f1b00
last_seen: 2026-07-30T11:16:00+09:00
---

# A stale installed plugin now offers a command name that no longer exists in source

## Description

The rename retires `/feedback` from source (see [0d696aec](https://github.com/qmu/workaholic/commit/0d696aec) in `plugins/workaholic/commands/fb.md`), but an installed marketplace copy refreshes on its own schedule, so a developer on a pre-refresh install still sees `/feedback` alongside the already-stale `/monitor`, `/trip`, and `/carry`. This case is worse than those: Claude Code's built-in `/feedback` occupies the same trigger, so the stale plugin entry and the built-in compete for one name and the developer cannot tell from the list which they will get. This aggravates the open stream concern `installed-plugin-lag-now-includes-commands`, and the branch adds neither a post-release note nor version-mismatch surfacing.

## How to Fix

Ship the v1.0.108 release note with an explicit "refresh the plugin; `/feedback` is now `/fb`" line, and add the version-mismatch surfacing that concern has been asking for — simplest form is a `SessionStart` check comparing the installed plugin's `plugin.json` version against the repo's `.claude-plugin/marketplace.json`, reporting a mismatch once per session.
