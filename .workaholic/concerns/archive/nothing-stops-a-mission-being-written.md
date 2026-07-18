---
type: Concern
concern_id: nothing-stops-a-mission-being-written
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
closed_reason: Promoted to ticket 20260716163004-mission-floor-machine-checks.md (2026-07-16 triage-to-zero): a PostToolUse mission.md validator on the same footing as validate-ticket.sh. Risk now tracked in the queue.
closed_at: 2026-07-16T17:09:47+09:00
---

# Nothing stops a mission being written incomplete off the sanctioned path

## Description

Two tickets hit this independently and neither could close it. [b75b83c0](https://github.com/qmu/workaholic/commit/b75b83c0) fixed the read path so an unassigned mission is no longer hidden, but notes "the read path no longer hides what exists, but nothing yet stops a mission being written incomplete" — the same hand-authored mission is also missing `gate_type`/`gate_target`/`gate_assert`. [3ead50ae](https://github.com/qmu/workaholic/commit/3ead50ae)'s interrogation is a **partial** closure of `missions-are-born-matching-the-lens` and the skill says so: `create.sh` is `allowed-tools: Bash` and still cannot interrogate, so a hand-authored `mission.md` bypassing `/mission` still arrives at 0/0 and stays invisible to the lens. There is no frontmatter validator for `mission.md` — the analogue of `validate-ticket.sh`, which tickets have had for months.

## How to Fix

Write a `mission.md` frontmatter/body validator on the same PostToolUse footing as `validate-ticket.sh`, checking `assignee`, the presence of a non-comment `## Experience`, and at least one `## Acceptance` item. This is the single fix that closes the residue of three separate tickets, and it is the machine-checked floor the carried compound `a-mission-can-carry-no-machine` asks for from the other direction.
