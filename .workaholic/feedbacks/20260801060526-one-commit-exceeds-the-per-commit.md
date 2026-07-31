---
type: Feedback
title: One commit exceeds the per-commit changed-lines ceiling
kind: concern
source: development
created_at: 2026-08-01T06:05:26+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: one-commit-exceeds-the-per-commit
owner: 
mission: 
tickets: [20260801031302-announce-a-claim-the-moment-it-is-pushed.md, 20260801031301-resume-a-claimed-but-unfinished-unit.md, 20260801031304-handoff-is-a-first-class-terminal-state.md]
origin_pr: 151
origin_pr_url: https://github.com/qmu/workaholic/pull/151
origin_branch: work-20260801-051742
origin_commit: 6c625c7b
last_seen: 2026-08-01T06:05:26+09:00
---

# One commit exceeds the per-commit changed-lines ceiling

## Description

The resume commit ([1472f42c](https://github.com/qmu/workaholic/commit/1472f42c)) carries 685 non-generated changed lines against a 500-line ceiling, so the branch-safety scan returns `block` with an overridable `too-large-commit` finding. The ticket is one coherent mechanism spanning the scan, the survey, the reader, the writer, the worktree creator and their tests; splitting it would either break one-ticket-one-commit or produce a commit whose tree cannot work (`plugins/workaholic/skills/drive/scripts/`).

## How to Fix

Either accept that a mechanism-wide ticket is legitimately over the ceiling and record the exemption criteria, or require such tickets to be decomposed at `/ticket` time rather than at drive time. The active mission *Make the per-commit changed-lines ceiling a rule that holds* is the right home for the ruling.
