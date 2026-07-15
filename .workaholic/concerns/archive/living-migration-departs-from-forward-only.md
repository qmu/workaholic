---
type: Concern
mission: 
tickets: [20260713103820-mission-active-archive-split-and-close.md]
origin_pr: 82
origin_pr_url: https://github.com/qmu/workaholic/pull/82
origin_branch: work-20260713-102453
origin_commit: 5d2efad
created_at: 2026-07-13T11:56:22+09:00
last_seen: 2026-07-13T11:56:22+09:00
first_seen: 2026-07-13T11:56:22+09:00
concern_id: living-migration-departs-from-forward-only
severity: low
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: The documentation obligation the concern set is discharged: mission/SKILL.md:36 records the scope, git-mv history preservation, idempotency and non-blocking behavior, and :196 names the exact read-only case ('the one tree change any reader can trigger'). The --skip-migration opt-out was conditional on side-effect reports; none exist.
closed_at: 2026-07-15T19:50:28+09:00
---

# Living migration departs from forward-only stance but is strictly scoped

## Description

This branch implements automatic file migration (git mv) to relocate legacy flat missions — a deliberate departure from concern #77's recorded stance of 'write a targeted migration ticket.' The migration is scoped strictly to mission dirs holding mission.md directly under .workaholic/missions/ and is best-effort (failures don't block calling seams), but it does mean read-only paths like /catch can move files.

## How to Fix

Document the scoping carefully in mission/SKILL.md; monitor for unexpected tree mutations in deployments and be prepared to add opt-out flags (--skip-migration) if deployments report side effects.
