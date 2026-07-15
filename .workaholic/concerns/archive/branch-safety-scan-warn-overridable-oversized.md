---
type: Concern
concern_id: branch-safety-scan-warn-overridable-oversized
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
status: resolved
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Scoped to PR #84's 103-file branch and already resolved by the recorded override at ship; its own How to Fix said 'None required'. Carries no forward condition: the current branch scans pass at 59 files, under MAX_FILES=100.
closed_at: 2026-07-15T19:50:28+09:00
---

# Branch-safety scan WARN (overridable): oversized change set

## Description

The scan's only remaining finding on this branch is `size/too-many-files` (103 > 100) — legitimate, because `outputs/` was regenerated across many commits. It is `override`-tier and is recorded at `/ship`, not a block.

## How to Fix

None required; `/ship` records the override in deployment evidence.
