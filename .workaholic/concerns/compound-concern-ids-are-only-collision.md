---
type: Concern
concern_id: compound-concern-ids-are-only-collision
mission: []
tickets: [20260715172302-scan-rule-secret-reads-a-call-as-a-literal.md, 20260716103000-mission-quality-gate-design.md, 20260716104000-check-worktrees-drops-the-last-worktree.md, 20260716124141-commit-sh-help-commits-and-a-stale-memory-cannot-be-corrected.md, 20260716153106-mission-natural-language-replan.md, 20260716163001-commit-sh-argument-and-subject-hardening.md, 20260716163002-catch-scan-window-blind-spots.md, 20260716163003-concern-machinery-robustness.md, 20260716163004-mission-floor-machine-checks.md, 20260716163005-release-scan-and-ship-gaps.md, 20260716163006-worktree-and-trip-association-gaps.md, 20260716163007-live-validation-session.md, 20260716211756-resume-triage-tickets-on-branch.md, 20260718185410-add-monitor-parallel-mission-driver.md, 20260718185411-quality-gate-interrogation-asks-decisions-only.md, 20260718191500-validate-ticket-resolves-mission-in-tickets-checkout.md, 20260718194500-monitor-pushes-decisions-one-by-one.md]
origin_pr: 88
origin_pr_url: https://github.com/qmu/workaholic/pull/88
origin_branch: work-20260716-152211
origin_commit: 70e5f3fb
created_at: 2026-07-18T20:46:34+09:00
first_seen: 2026-07-18T20:46:34+09:00
last_seen: 2026-07-21T11:26:01+09:00
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Compound concern IDs are only collision-checked at mint time

## Description

`merge-concerns.sh` refuses a compound-id collision when minting, but hand-authored or hand-edited concern files are never re-checked, so a manually created duplicate id would go unnoticed until it misroutes an update (see [328981db](https://github.com/qmu/workaholic/commit/328981db) in `plugins/workaholic/skills/report/scripts/`)

## How to Fix

Add a duplicate-id warning to `list-active-deferred-concerns.sh`'s identity migration pass, where every file is already read.

