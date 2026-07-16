---
type: Concern
concern_id: mid-run-ticket-minting-s-failure
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
closed_reason: The mint threshold is inherently a model judgment no script can decide; the acceptance-list drift is a documented deliberate trade-off (the queue reflects reality, the acceptance list the agreement).
closed_at: 2026-07-16T17:06:06+09:00
---

# Mid-run ticket minting's failure mode is over-minting, and the threshold is prose

## Description

[2666cea9](https://github.com/qmu/workaholic/commit/2666cea9) lets an unattended run write a ticket for an out-of-scope problem and continue. The failure mode is over-minting: a queue of auto-written tickets nobody asked for looks like a plan and is worse than a report paragraph. The threshold — mint only for a problem the run actually **hit**, never a speculative improvement — is prose pinned by a regex against the skill, not a check; no script can decide it, because the judgment is a model's. Accepted knowingly and worth watching: a minted ticket does **not** append an acceptance item, so a mission's ticket set can drift from its `## Acceptance` list (the queue reflects reality, the acceptance list reflects the agreement).

## How to Fix

Review the first real unattended run's minted tickets against what the run actually hit; if speculative tickets appear, tighten the rule at the point of minting rather than in the report. Do not "fix" the acceptance drift by auto-appending — progress is `checked ÷ total` computed from that list, so appending criteria mid-run grows the denominator and makes a mission visibly recede while being advanced, against criteria nobody agreed to.
