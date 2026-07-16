---
type: Concern
concern_id: validate-ticket-sh-is-a-posttooluse
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

# validate-ticket.sh is a PostToolUse review, not a guard, and blocks mid-authoring

## Description

[e12448d4](https://github.com/qmu/workaholic/commit/e12448d4) enforces `## Policies` and `## Quality Gate`, but the hook is **PostToolUse** — it rejects loudly, it cannot stop the file existing. It therefore also **blocks mid-authoring for any hand-authored ticket**, a real cost the developer accepted deliberately on the reasoning that `create-ticket` writes a complete ticket in one Write. That reasoning is demonstrably incomplete: the same session's verification rejected an untracked ticket stamped 02:10 that day, written outside the session, carrying the identical section-less shape — so the sanctioned path is provably not the only one. This is the same "a default on the sanctioned path does not constrain the other paths" shape that [b75b83c0](https://github.com/qmu/workaholic/commit/b75b83c0) and [3ead50ae](https://github.com/qmu/workaholic/commit/3ead50ae) each hit independently.

## How to Fix

Live with the PostToolUse position (a PreToolUse hook cannot see body content that Write is about to create any more usefully) but watch for hand-authoring friction; if it bites, the answer is a `--draft` location that is not retro-checked, not a weaker check. Critically, the check must **not** grow toward judging gate *quality* — that is semantic and belongs to the interrogation and the developer, a lesson this repo already paid for with the deleted internal-hostname leak pattern. The deferred question this raises: an unattended drive may want to check the gate *before starting*, rather than trusting that a write-time review was never bypassed.
