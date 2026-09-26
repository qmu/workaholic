---
type: Mission
title: Merge pull requests so landed branches read as merged
slug: merge-pull-requests-so-landed-branches-read-as-merged
status: active
merge_policy:
created_at: 2026-09-26T17:37:04+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260926173452-stop-squash-merging-so-landed-branches-read-as-merged.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Merge pull requests so landed branches read as merged

## Goal

The developer asked the loop to stop squash-merging (2026-09-26, #1279): a landed `work-*`
branch must read as merged, so finished branches stop piling up looking unfinished. This
supersedes the 2026-09-01 squash ruling; its stated cost (bookkeeping commits reach `main`)
is accepted and kept readable through `git log --first-parent`.

## Experience

After a unit's pull request merges, `git branch --merged origin/main` lists its branch and
`survey-worktrees.sh` reads its worktree `merged: true`, so the hourly sweep reclaims it.
`git log --first-parent main` still reads as one line per landed unit.

## Acceptance

- [ ] Every merge site merges with a merge commit, derived by `merge-method.sh` (#20260926173821-merge-every-pull-request-with-a-merge-commit.md)
- [ ] A landed branch and its worktree read as merged by ancestry and are reclaimed (#20260926173821-read-and-reclaim-landed-branches-by-ancestry.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
