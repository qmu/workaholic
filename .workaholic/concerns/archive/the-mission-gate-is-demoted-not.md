---
type: Concern
concern_id: the-mission-gate-is-demoted-not
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
closed_reason: Measure-then-decide stance held; the gate was invested in rather than deleted (check gate_type, fea159ba). The delete-vs-keep call remains a future measurement, not present work.
closed_at: 2026-07-16T17:06:21+09:00
---

# The mission gate is demoted, not deleted, and is now maintained-but-uncalled

## Description

[54e5ec65](https://github.com/qmu/workaholic/commit/54e5ec65) made `gate_type`/`gate_target`/`gate_assert` optional and normally empty on the measured grounds that they were already universally unfilled and structurally unrunnable. But `gate.sh` and the carried-inheritance path still read them, and [4899063d](https://github.com/qmu/workaholic/commit/4899063d) — driven three hours earlier in the same queue — just *fixed* the worktree port resolution those fields feed. Its own Final Report names the trap: "this fixes a reader for fields 54e5ec65 just demoted to optional: if `gate_*` stays universally empty over the next few missions, the honest follow-up is to delete the fields and this script rather than maintain a working reader nobody calls." So the branch now carries a correct, tested reader for data that the same branch decided should normally not exist. `## Experience`, which replaced the gate as the mission's substance, is prose and loses the gate's one real virtue — objectivity — which survives only as a convention the SKILL states rather than checks.

## How to Fix

Set a review point (e.g. after the next three real missions) and check whether any filled `gate_*`. If none did, delete the fields, `gate.sh`, and the carried-inheritance read outright rather than maintaining them — a mechanism nobody uses is not free just because it works. If some did, the demotion was wrong and the fields deserve their objectivity back. Decide on measurement, which is exactly how the demotion itself was justified.
