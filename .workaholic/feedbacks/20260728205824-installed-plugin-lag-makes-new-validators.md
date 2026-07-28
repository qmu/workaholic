---
type: Feedback
title: Installed-plugin lag makes new validators inert until this branch merges
kind: concern
source: development
created_at: 2026-07-28T20:58:24+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: installed-plugin-lag-makes-new-validators
owner: a@qmu.jp
mission: [loop-engineering-foundation]
tickets: [20260728183201-add-feedback-artifact-and-capture-skill.md, 20260728183202-carry-mission-ownership-on-assignees.md, 20260728183203-retire-strategy-layer.md]
origin_pr: 98
origin_pr_url: https://github.com/qmu/workaholic/pull/98
origin_branch: work-20260728-183130
origin_commit: 171b80fd
last_seen: 2026-07-28T20:58:24+09:00
---

# Installed-plugin lag makes new validators inert until this branch merges

## Description

`validate-feedback.sh` and the updated `validate-ticket.sh`/`validate-mission.sh` only enforce once the installed plugin updates to this branch's code — until merge (and plugin refresh), a Write-tool feedback write is judged by the *old* hook set, and in repos that never update the plugin the feedback floor never fires at all (see [ef988253](https://github.com/qmu/workaholic/commit/ef988253) in `plugins/workaholic/hooks/validate-feedback.sh`). The same distribution gap previously left leak rules inert in uninstalled repos.

## How to Fix

Ship promptly and rely on marketplace auto-update; for the loop-engineering phases, make the 5-minute routine run from a checkout that tracks main so hooks are always current.
