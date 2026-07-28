---
type: Feedback
title: Draft Acceptance sketches could be mistaken for plans
kind: concern
source: development
created_at: 2026-07-28T21:56:35+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: draft-acceptance-sketches-could-be-mistaken
owner: a@qmu.jp
mission: [loop-engineering-proposal-loop]
tickets: [20260728210301-merge-concern-corpus-into-feedback-stream.md, 20260728210302-add-proposal-batch-command-and-skill.md, 20260728210303-add-slack-notifier-and-proposal-runbook.md]
origin_pr: 99
origin_pr_url: https://github.com/qmu/workaholic/pull/99
origin_branch: work-20260728-210259
origin_commit: 773ff9db
last_seen: 2026-07-28T21:56:35+09:00
---

# Draft Acceptance sketches could be mistaken for plans

## Description

A draft mission's `## Acceptance` is a proposal sketch, marked provisional only by scaffold comments and the `draft` status; a hasty human could authorize a draft as-is, skipping the replan that approval is supposed to trigger (see [70bea0a4](https://github.com/qmu/workaholic/commit/70bea0a4) in `plugins/workaholic/skills/propose/scripts/scaffold-draft.sh`)

## How to Fix

Phase 3's approval flip should make replan-to-drive-ready a structural step of approval (draft → interrogated → authorized), not an honor-system convention.
