---
type: Concern
concern_id: monitor-s-decision-loop-has-no
mission: []
tickets: [20260715172302-scan-rule-secret-reads-a-call-as-a-literal.md, 20260716103000-mission-quality-gate-design.md, 20260716104000-check-worktrees-drops-the-last-worktree.md, 20260716124141-commit-sh-help-commits-and-a-stale-memory-cannot-be-corrected.md, 20260716153106-mission-natural-language-replan.md, 20260716163001-commit-sh-argument-and-subject-hardening.md, 20260716163002-catch-scan-window-blind-spots.md, 20260716163003-concern-machinery-robustness.md, 20260716163004-mission-floor-machine-checks.md, 20260716163005-release-scan-and-ship-gaps.md, 20260716163006-worktree-and-trip-association-gaps.md, 20260716163007-live-validation-session.md, 20260716211756-resume-triage-tickets-on-branch.md, 20260718185410-add-monitor-parallel-mission-driver.md, 20260718185411-quality-gate-interrogation-asks-decisions-only.md, 20260718191500-validate-ticket-resolves-mission-in-tickets-checkout.md, 20260718194500-monitor-pushes-decisions-one-by-one.md]
origin_pr: 88
origin_pr_url: https://github.com/qmu/workaholic/pull/88
origin_branch: work-20260716-152211
origin_commit: 70e5f3fb
created_at: 2026-07-18T20:46:34+09:00
first_seen: 2026-07-18T20:46:34+09:00
last_seen: 2026-07-18T20:46:34+09:00
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Monitor's decision loop has no cross-run deferral memory

## Description

The push-decisions contract asks blockers one at a time until answered or explicitly deferred (see [edf246a4](https://github.com/qmu/workaholic/commit/edf246a4) in `plugins/workaholic/skills/monitor/SKILL.md` §1/§3). The wave cap bounds driving, but nothing makes a deferral sticky across invocations — a caller-side loop would re-ask the same deferred decisions every cycle.

## How to Fix

Record deferred decisions in the run report and have the next invocation re-ask only when the underlying state changed (or after N runs), so deferral is remembered rather than re-litigated every loop.

## Re-judgment (2026-07-21, mission reorganize-missions-under-strategies)

Reviewed while adding the `/monitor` completion report and per-mission `## Reflection` (ticket 20260721025718). **Still active — re-deferred.** The new reflection mechanism records the *causes* that stopped or would have stopped autonomy (`blocked` / `leaked questions` / `front-load next:`) and feeds them into the next Creation Interrogation, which sharpens planning — but it deliberately does **not** make a deferred *decision* sticky across `/monitor` invocations (the ticket's own Considerations forbid blurring reflection-causes with the escalation list of pending decisions). Cross-run deferral memory for escalations remains unaddressed; this concern's fix is a distinct mechanism.
