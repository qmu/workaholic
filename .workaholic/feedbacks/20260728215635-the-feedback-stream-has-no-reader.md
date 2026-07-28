---
type: Feedback
title: The feedback stream has no reader-side scale valve yet
kind: concern
source: development
created_at: 2026-07-28T21:56:35+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-feedback-stream-has-no-reader
owner: a@qmu.jp
mission: [loop-engineering-proposal-loop]
tickets: [20260728210301-merge-concern-corpus-into-feedback-stream.md, 20260728210302-add-proposal-batch-command-and-skill.md, 20260728210303-add-slack-notifier-and-proposal-runbook.md]
origin_pr: 99
origin_pr_url: https://github.com/qmu/workaholic/pull/99
origin_branch: work-20260728-210259
origin_commit: 773ff9db
last_seen: 2026-07-28T21:56:35+09:00
---

# The feedback stream has no reader-side scale valve yet

## Description

With the promotion floor retired, every concern of every severity accumulates in `feedbacks/`, and `list-open-concerns.sh` reads the whole directory per invocation; the stream's growth is by design, but no consumer yet summarizes or windows it for the judge/planning readers when it reaches hundreds of open records (see [f8967270](https://github.com/qmu/workaholic/commit/f8967270) in `plugins/workaholic/skills/feedback/scripts/list-open-concerns.sh`)

## How to Fix

If judge tool-budgets start straining, add a windowing/summary mode to the single reader (e.g. group by origin branch, cap bodies) rather than reintroducing write-side curation.
