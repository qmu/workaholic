---
type: Concern
concern_id: the-trip-branch-association-does-not
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
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Promoted to ticket 20260716163006-worktree-and-trip-association-gaps.md (2026-07-16 triage-to-zero): decide and record the trip-to-branch association, then make detect-context.sh answer it. Risk now tracked in the queue.
closed_at: 2026-07-16T17:10:09+09:00
---

# The trip↔branch association does not exist, so a work-* branch can never report trip

## Description

[e81d561c](https://github.com/qmu/workaholic/commit/e81d561c) fixed the mis-detection by narrowing `has_trips` to the legacy `trip/<name>` association only (`detect-context.sh:47-52`, via `branch_trip_dir`). That is correct for the defect it targeted, but it leaves the trip path **inoperative end-to-end for modern branches, not merely mis-detected**: `detect-context.sh` emits `trip_name` only for `trip/*` branches (`detect-context.sh:93`), so `report/SKILL.md`'s Trip Mode step 3 cannot resolve `<trip-name>` on a `work-*` branch either. The gate row "a branch with its own trip dir → trip" now holds only for legacy `trip/*` branches. Two candidate associations were costed and rejected as too big for a bugfix: a git-history test (untracked, or introduced by `main..HEAD`), and stamping `branch:` into `plan.md` (which breaks when a trip is resumed on another branch).

## How to Fix

Define the trip↔branch association as its own decision, and answer `has_trips` **and** `trip_name` together — fixing either alone leaves the other silently wrong, which is the precise failure this concern exists to prevent. Until then, treat `mode: trip` as reachable only from a `trip/*` branch and do not add trip-mode behavior that a `work-*` branch is expected to trigger.
