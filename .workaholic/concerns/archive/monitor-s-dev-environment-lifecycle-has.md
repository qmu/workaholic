---
type: Concern
concern_id: monitor-s-dev-environment-lifecycle-has
mission: []
tickets: [20260715172302-scan-rule-secret-reads-a-call-as-a-literal.md, 20260716103000-mission-quality-gate-design.md, 20260716104000-check-worktrees-drops-the-last-worktree.md, 20260716124141-commit-sh-help-commits-and-a-stale-memory-cannot-be-corrected.md, 20260716153106-mission-natural-language-replan.md, 20260716163001-commit-sh-argument-and-subject-hardening.md, 20260716163002-catch-scan-window-blind-spots.md, 20260716163003-concern-machinery-robustness.md, 20260716163004-mission-floor-machine-checks.md, 20260716163005-release-scan-and-ship-gaps.md, 20260716163006-worktree-and-trip-association-gaps.md, 20260716163007-live-validation-session.md, 20260716211756-resume-triage-tickets-on-branch.md, 20260718185410-add-monitor-parallel-mission-driver.md, 20260718185411-quality-gate-interrogation-asks-decisions-only.md, 20260718191500-validate-ticket-resolves-mission-in-tickets-checkout.md, 20260718194500-monitor-pushes-decisions-one-by-one.md]
origin_pr: 88
origin_pr_url: https://github.com/qmu/workaholic/pull/88
origin_branch: work-20260716-152211
origin_commit: 70e5f3fb
created_at: 2026-07-18T20:46:34+09:00
first_seen: 2026-07-18T20:46:34+09:00
last_seen: 2026-07-18T20:46:34+09:00
severity: moderate
status: superseded
resolved_by_pr: 
resolved_by_commit: 
superseded_by: monitor-s-contract-is-verified-only
---

# Monitor's dev-environment lifecycle has no test coverage

## Description

`/monitor` now boots each driven mission's declared dev environment at dispatch and stops what it started at the terminal state (see [edf246a4](https://github.com/qmu/workaholic/commit/edf246a4) in `plugins/workaholic/skills/monitor/SKILL.md` §2), but boot failure, port-in-use, and teardown paths have no smoke assertions and no live validation — the E2E ran on a project with no declared dev command.

## How to Fix

Add hermetic fixtures for boot-with-conflict, no-declaration (skip), and stop-only-what-we-started; exercise once against a real project with a declared dev command.

## Re-judgment (2026-07-21, mission reorganize-missions-under-strategies)

Reviewed while adding the `/monitor` completion report and per-mission `## Reflection` (ticket 20260721025718). **Still active — re-deferred.** This ticket adds hermetic coverage for the reflection mutator/reader and the completion-report vocabulary, but touches none of the dev-environment lifecycle (boot-with-conflict, no-declaration skip, stop-only-what-we-started) — that coverage is still absent and out of this ticket's scope. Reason unchanged.
