---
type: Concern
concern_id: the-0-0-handoff-rule-deliberately
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

# The 0/0 handoff rule deliberately inverts the mission lens's signal gate

## Description

[1d1bc5bb](https://github.com/qmu/workaholic/commit/1d1bc5bb) makes `/carry` **announce** a 0/0 mission, while the mission lens deliberately **silences** one. Two readers of the same field with opposite thresholds is exactly the shape someone later "fixes" into consistency — and it is the **third** such deliberate divergence in the mission model, alongside `/mission summary`'s lower assignee bar (assignee alone, versus the lens's three gates). The divergence and its reason are stated in the skill and pinned by a test, which is the honest ceiling for a prose rule, but the branch's own Final Report names this as the most fragile thing it built. Related: `/report` and `/ship` deliberately do **not** state mission position, because the report exists for continuity across a session boundary and neither crosses one.

## How to Fix

Before "unifying" any two mission-model thresholds, read why they diverge — each divergence is decided, not drift: the lens is an unasked nudge (so a 0/0 mission has nothing to act on), the handoff is a requested report (so a 0/0 mission is exactly what a fresh session must be told). If the three divergences ever become hard to keep straight, document them in one place as a table of reader × threshold × reason rather than collapsing them. Revisit `/report`'s silence only if a PR reviewer has to ask which mission a story belongs to.
