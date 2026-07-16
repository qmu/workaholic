---
type: Concern
concern_id: the-successor-mission-loses-its-predecessor
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

# The successor mission loses its predecessor's worktree, in-flight state, and ports

## Description

[a027cd1b](https://github.com/qmu/workaholic/commit/a027cd1b)'s `carried` close deliberately gives the successor **no** worktree, so in-flight state and the port allocation are lost and must be rebuilt through the normal `/mission` flow. The reason is measured, not incidental: `.worktrees/<slug>` is keyed 1:1 to the mission slug, and a successor living in the predecessor's directory silences the mission lens inside that very worktree — the mission being worked on becomes the one mission invisible. A rename primitive (`git worktree move`) would preserve both cleanly but none exists today and it widens an otherwise independent ticket. Separately: `carried` must not become a way to avoid saying `abandoned` — a successor nobody drives is an abandoned mission with a longer name, and the only guard is that `/mission summary` and the lens now surface an unclaimed successor.

## How to Fix

Add a worktree-rename primitive as a follow-up so a carry preserves in-flight state and the port allocation instead of discarding them. Independently, watch the archive for `carried` missions whose successors sit unclaimed and undriven; if the pattern appears, `carried` is being used to dodge `abandoned` and the close flow should say so.
