---
type: Feedback
title: The archive commit exceeds the per-commit changed-lines ceiling
kind: concern
source: development
created_at: 2026-08-01T02:11:56+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-archive-commit-exceeds-the-per
owner: 
mission: []
tickets: [20260731163049-propose-surveys-repo-state-and-lands-on-a-branch.md]
origin_pr: 124
origin_pr_url: https://github.com/qmu/workaholic/pull/124
origin_branch: work-20260801-012313
origin_commit: ea3765b8
last_seen: 2026-08-01T02:11:56+09:00
---

# The archive commit exceeds the per-commit changed-lines ceiling

## Description

The branch-safety scan reports `too-large-commit` — 685 non-generated changed lines against a 500 ceiling — on [5b2b2a7b](https://github.com/qmu/workaholic/commit/5b2b2a7b). The `outputs/**` rebuild is correctly exempted, so the overage is genuine source: three new scripts totalling ~430 lines, plus documentation across five files and two new test blocks. The route is unaffected (this unit is `review`, so it stops at a PR either way), but the commit is not the comparable throughput unit the rule intends.

## How to Fix

`archive.sh` produces exactly one commit per ticket, so a ticket this size cannot satisfy the ceiling by construction. Either the ticket is decomposed at creation time — the scripts, the docs, and the generalization to `/ticket`//`mission` are three plausible tickets — or the ceiling acknowledges an archive commit's floor. The active mission *Make the per-commit changed-lines ceiling a rule that holds* is where that decision belongs.
