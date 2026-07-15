---
type: Concern
concern_id: report-step-1-wording-predates-the
mission: 
tickets: [20260714000528-command-summary-mode.md, 20260714001859-mission-branch-on-create.md, 20260714010905-document-root-env-worktree-convention-in-branching-skill.md, 20260714011846-mission-worktree-primitive.md, 20260714011847-mission-create-worktree-kickoff.md, 20260714011848-ship-preserve-mission-worktree.md, 20260714011849-mission-close-remove-worktree.md, 20260714014042-mission-lens-worktree-focus.md, 20260714014043-mission-worktree-port-assignment.md, 20260714014044-mission-quality-gate.md, 20260714103349-release-scan-engine.md, 20260714103350-wire-release-scan-report-ship.md]
origin_pr: 84
origin_pr_url: https://github.com/qmu/workaholic/pull/84
origin_branch: work-20260714-000543
origin_commit: a1bb87a
created_at: 2026-07-14T16:15:36+09:00
first_seen: 2026-07-14T16:15:36+09:00
last_seen: 2026-07-14T16:15:36+09:00
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# report step-1 wording predates the tiered scan severities

## Description

`report/SKILL.md` step 1 says "force `releasable: false` on a block," but the scan now has an `override` tier that should warn-and-record rather than block. The release-readiness pass handled this correctly (it treated the override size finding as non-blocking), but the wording should distinguish `hard`/`confirm` (force not-releasable) from `override` (warn).

## How to Fix

Reconcile the step-1 wording to key off severity, not just "block."
