---
type: Feedback
title: Prompt comparison is exact, so reformatting a template flags every repository at once
kind: concern
source: development
created_at: 2026-08-01T04:20:02+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: prompt-comparison-is-exact-so-reformatting
owner: 
mission: []
tickets: [20260801030421-workaholify-provisions-the-loop-engineering-environment.md]
origin_pr: 138
origin_pr_url: https://github.com/qmu/workaholic/pull/138
origin_branch: work-20260801-033154
origin_commit: 2c2db915
last_seen: 2026-08-01T04:20:02+09:00
---

# Prompt comparison is exact, so reformatting a template flags every repository at once

## Description

`compare-routines.sh` compares prompts after trimming and nothing else. Any future edit to a template — including whitespace — reports drift for every repository that has that routine.

## How to Fix

Nothing; this is the intended trade. Fuzzy matching would hide the single-line drift this exists to detect. Worth knowing before editing a template casually.
