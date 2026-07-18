---
type: Concern
concern_id: gate-sh-s-main-checkout-half
mission: []
tickets: [20260715213320-surface-the-ship-flow-push-outcome.md, 20260715213321-compound-concern-identity-and-provenance.md, 20260715213322-scope-trip-mode-to-the-branch.md, 20260715215008-summary-unassigned-missions.md, 20260716012845-mission-interrogation-emits-ticket-set.md, 20260716012846-enforce-quality-gate-section.md, 20260716012847-drive-a-mission-authorized-queue.md, 20260716012848-mission-carry-over-successor.md, 20260716021000-gate-sh-worktree-port-resolution.md, 20260716102950-mission-describes-experience-not-gate.md, 20260716102951-drive-writes-tickets-for-midrun-problems.md, 20260716102952-mission-position-is-always-reported.md]
origin_pr: 87
origin_pr_url: https://github.com/qmu/workaholic/pull/87
origin_branch: work-20260715-213222
origin_commit: 9065d7a1
created_at: 2026-07-16T12:06:03+09:00
first_seen: 2026-07-16T12:06:03+09:00
last_seen: 2026-07-16T12:06:03+09:00
severity: low
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Both halves are documented scope calls: not_found from the main checkout is honest, and CWD-relative mission_resolve is harmless because every workflow runs from a checkout root.
closed_at: 2026-07-16T17:06:06+09:00
---

# gate.sh's main-checkout half is deliberately unfixed, and mission_resolve is CWD-relative

## Description

A recorded scope call from [4899063d](https://github.com/qmu/workaholic/commit/4899063d): `gate.sh <slug>` run from the main checkout for a mission created in a worktree still returns `not_found`, which is correct — the mission is genuinely not there, it lives on the worktree's branch — and `not_found` already names the reason. Resolving it would mean scanning every worktree for the mission, changing what `mission_resolve` means for every mission script. A related latent constraint was found while testing: `mission_resolve` reads a CWD-relative `.workaholic/`, so **no** mission script resolves a bare slug from a subdirectory. Harmless today because the workflows always run from a checkout root; invisible until someone invokes them by hand.

## How to Fix

Leave the main-checkout half alone unless a real caller needs it — `not_found` is honest. If `mission_resolve` is ever revisited, resolve `.workaholic/` from the repo root rather than CWD so hand invocation from a subdirectory stops silently failing, and note that this changes resolution semantics for every mission script at once.
