---
type: Concern
concern_id: the-approval-free-drive-is-unproven
mission: []
tickets: [20260715213320-surface-the-ship-flow-push-outcome.md, 20260715213321-compound-concern-identity-and-provenance.md, 20260715213322-scope-trip-mode-to-the-branch.md, 20260715215008-summary-unassigned-missions.md, 20260716012845-mission-interrogation-emits-ticket-set.md, 20260716012846-enforce-quality-gate-section.md, 20260716012847-drive-a-mission-authorized-queue.md, 20260716012848-mission-carry-over-successor.md, 20260716021000-gate-sh-worktree-port-resolution.md, 20260716102950-mission-describes-experience-not-gate.md, 20260716102951-drive-writes-tickets-for-midrun-problems.md, 20260716102952-mission-position-is-always-reported.md]
origin_pr: 87
origin_pr_url: https://github.com/qmu/workaholic/pull/87
origin_branch: work-20260715-213222
origin_commit: 9065d7a1
created_at: 2026-07-16T12:06:03+09:00
first_seen: 2026-07-16T12:06:03+09:00
last_seen: 2026-07-16T12:06:03+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# The approval-free drive is unproven end-to-end and the suite structurally cannot prove it

## Description

[b9d893e6](https://github.com/qmu/workaholic/commit/b9d893e6)'s criterion 7 — the live end-to-end run — was **not performed**, and its Final Report records this explicitly rather than glossing it. The gate asks for a real `/mission` followed by a `/drive` of its queue observing zero prompts, which needs a model-driven session against a real mission worktree; this drive ran under a different authorization (`/goal`), so a run here would demonstrate the goal's authorization rather than the stamp's. Criteria 1-6 are green and the script seam (`mission/scripts/drive-authorized.sh`) is well covered — authorized/no_mission/not_authorized/mission_not_found, the conservative two-mission row, bare-vs-list relation equivalence — but the suite never runs a model, so the thing that was actually shipped (a `/drive` that stops asking) has never been observed. The same hole applies to [2666cea9](https://github.com/qmu/workaholic/commit/2666cea9): no script decides "is this problem in scope?" — a model does, and its live row is likewise uncovered. These are the two most behavior-changing features on the branch and they share one unproven seam.

## How to Fix

Run a real `/mission` interrogation followed by a `/drive` of its queue in a mission worktree, observing zero Step 2.2 prompts and confirming a mid-run out-of-scope problem produces a ticket rather than a stop or a narrated paragraph. Do this before relying on either flow unattended, and record the run as the evidence criterion 7 asks for. Do not close either ticket's gate on the hermetic suite alone — its inability to run a model is structural, not a coverage gap to be filled.
