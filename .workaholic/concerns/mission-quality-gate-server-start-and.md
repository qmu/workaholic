---
type: Concern
concern_id: mission-quality-gate-server-start-and
mission: 
tickets: [20260714000528-command-summary-mode.md, 20260714001859-mission-branch-on-create.md, 20260714010905-document-root-env-worktree-convention-in-branching-skill.md, 20260714011846-mission-worktree-primitive.md, 20260714011847-mission-create-worktree-kickoff.md, 20260714011848-ship-preserve-mission-worktree.md, 20260714011849-mission-close-remove-worktree.md, 20260714014042-mission-lens-worktree-focus.md, 20260714014043-mission-worktree-port-assignment.md, 20260714014044-mission-quality-gate.md, 20260714103349-release-scan-engine.md, 20260714103350-wire-release-scan-report-ship.md]
origin_pr: 84
origin_pr_url: https://github.com/qmu/workaholic/pull/84
origin_branch: work-20260714-000543
origin_commit: a1bb87a
created_at: 2026-07-14T16:15:36+09:00
first_seen: 2026-07-14T16:15:36+09:00
last_seen: 2026-07-15T20:55:56+09:00
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Mission quality gate: server-start and live verification are not hermetic

## Description

`gate.sh` is declaration-and-ports only; the server start and the Playwright drive are in-session steps outside the suite (see `plugins/workaholic/skills/mission/scripts/gate.sh`).

## How to Fix

Split declaration from verification-run if the run side grows.

