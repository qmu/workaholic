---
type: Feedback
title: `commit-release-note.sh` shares the location assumption, correctly for now
kind: concern
source: development
created_at: 2026-07-30T19:54:39+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: commit-release-note-sh-shares-the
owner: 
mission: []
tickets: [20260730190856-merge-pr-breaks-in-a-claim-worktree.md]
origin_pr: 113
origin_pr_url: https://github.com/qmu/workaholic/pull/113
origin_branch: work-20260730-193046
origin_commit: 921d0cbc
last_seen: 2026-07-30T19:54:39+09:00
---

# `commit-release-note.sh` shares the location assumption, correctly for now

## Description

It pushes to the current branch, which is right because it runs **pre-merge** — the note must ride into the merge — so it was confirmed rather than changed (see [7642ebaa](https://github.com/qmu/workaholic/commit/7642ebaa) in `plugins/workaholic/skills/ship/scripts/`). But the reason it is correct is an ordering property of the Ship Flow, not anything the script itself checks: if a future flow ever called it after the merge, it would push a release note to a dead branch exactly as the extractor did, and report success.

## How to Fix

Have it assert its own precondition — refuse when the PR it is noting is already merged (`gh pr view --json merged`, or a passed-in flag) — so the ordering that makes it correct is enforced where it is relied upon rather than documented one step away.
