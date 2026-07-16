---
type: Concern
concern_id: the-compound-id-slug-collision-is
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

# The compound-id slug collision is real, measured, and inherited

## Description

[43c75292](https://github.com/qmu/workaholic/commit/43c75292) closed the compound round trip by deriving the id from `slugify(title)` instead of letting the caller invent one. The 6-word/60-char truncation collision this introduces was **measured, not argued**: two unrelated compounds sharing their first six words derive one id and the second silently folds into the first. This is a property of the shared slugify scheme that `extract-deferred-concerns.sh` already had — deriving the compound id inherits the risk rather than introducing it, trading an always-broken round trip for a rare title collision, which is the right trade. It is live on this very branch: `a-mission-can-carry-no-machine` and `closing-the-default-commit-path-routes` are both six-word truncations, and any future compound opening with the same six words would silently merge into them. Separately, `slugify` is now duplicated a **third** time by deliberate decision (the cross-skill closure cost was measured as real); the three copies are pinned to agree only by `testSlugifyWritersAgree`, making that test load-bearing.

## How to Fix

Give the collision its own ticket. The cheapest honest fix is a short hash suffix on the truncated slug (preserving readability while restoring uniqueness); the alternative is detecting a collision at mint time and refusing rather than folding. Do not "simplify" the three slugify copies into one without re-measuring the closure cost — and never delete `testSlugifyWritersAgree`, which is the only thing keeping them in agreement.
