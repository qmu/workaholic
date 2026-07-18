---
type: Concern
concern_id: monitor-s-contract-lives-in-prose
mission: []
tickets: [20260715172302-scan-rule-secret-reads-a-call-as-a-literal.md, 20260716103000-mission-quality-gate-design.md, 20260716104000-check-worktrees-drops-the-last-worktree.md, 20260716124141-commit-sh-help-commits-and-a-stale-memory-cannot-be-corrected.md, 20260716153106-mission-natural-language-replan.md, 20260716163001-commit-sh-argument-and-subject-hardening.md, 20260716163002-catch-scan-window-blind-spots.md, 20260716163003-concern-machinery-robustness.md, 20260716163004-mission-floor-machine-checks.md, 20260716163005-release-scan-and-ship-gaps.md, 20260716163006-worktree-and-trip-association-gaps.md, 20260716163007-live-validation-session.md, 20260716211756-resume-triage-tickets-on-branch.md, 20260718185410-add-monitor-parallel-mission-driver.md, 20260718185411-quality-gate-interrogation-asks-decisions-only.md, 20260718191500-validate-ticket-resolves-mission-in-tickets-checkout.md, 20260718194500-monitor-pushes-decisions-one-by-one.md]
origin_pr: 88
origin_pr_url: https://github.com/qmu/workaholic/pull/88
origin_branch: work-20260716-152211
origin_commit: 70e5f3fb
created_at: 2026-07-18T20:46:34+09:00
first_seen: 2026-07-18T20:46:34+09:00
last_seen: 2026-07-18T20:46:34+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# Monitor's contract lives in prose pinned only by sentinels

## Description

The monitor behavioral contract (push-decisions, dispatcher, env lifecycle) is orchestration prose pinned by fifteen sentence-level assertions (see [edf246a4](https://github.com/qmu/workaholic/commit/edf246a4) in `scripts/test-workflow-scripts.mjs`); a rewording that keeps the meaning but drops a sentinel fails the suite, while one that keeps the sentinel but drifts the meaning passes it.

## How to Fix

When editing monitor prose, update the sentinels deliberately in the same change; if the contract grows, promote stable parts into scripts (the `drive-authorized.sh` move) rather than more sentences.
