---
type: Feedback
title: Make /work own completion on Codex and Claude Code
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-06T08:14:15+09:00
author: a@qmu.jp
supersedes: 
---

# Make /work own completion on Codex and Claude Code

Source: https://github.com/qmu/workaholic/issues/994

The operator expects asking Codex to start Workaholic `/work` to have the same practical
outcome as asking a capable coding agent directly: recover the existing open pull requests,
resolve conflicts and failing checks, merge them sequentially in dependency order, implement
the queued tickets, and merge the resulting pull requests — continuing autonomously with
periodic, concise progress reports and a delivered completion report. Routine engineering
decisions, recoverable prerequisites and workflow bookkeeping must not become handoffs to the
operator. This is an explicit request to change that experience, **including existing
workaholic rules that currently make those states human-owned**; it is not a request to
improve notification wording. The outcome contract applies to both Claude Code and Codex,
with execution adapted to the actual harness.

## Observed failure

Sanitized observations from a consuming installation: after `/work` startup reported success,
repeated ticks reported 28 waiting tickets, **zero claimable units, and no implement worker**.
Four open pull requests were conflicting. Proposal workers repeatedly finished without
creating anything because work was already waiting. Completion announcements for older closed
asks stayed `thread_unresolved`. These are distinct failures: unfinished work has no
completion to announce, and already-finished work can separately lack delivery. A previous
supervisor kept reporting `ready` after its cached plugin version disappeared; its final
report said it could not execute the tick.

## The seams the ask names

Inspected at `9b94f2152`.

- `skills/loops/scripts/claimable-units.sh:100-104` counts missions, backlog and only
  `heartbeat_lapsed` / `report_incomplete` resumptions. That is narrower than the recovery and
  delivery work `skills/drive/SKILL.md` describes, and a zero allocation prevents the very
  `/implement` pass that would inspect open pull requests, undelivered units and stranded
  publications. Dispatch eligibility must include actionable recovery/delivery even with no
  newly claimable ticket.
- `skills/drive/SKILL.md` treats several parked, content-conflict and declared-verification
  states as waiting on a person. Reconcile those policies with the requested autonomy: let the
  agent inspect intent, resolve substantive conflicts, repair checks and revisit obsolete
  handoff assumptions. **A classifier's refusal of a mechanical script is not proof that a
  coding agent cannot finish the work.**
- `skills/work/scripts/codex-loop.sh:228-275` defaults to `ready` and infers failure from
  selected words in a free-text report; `run_worker` records a finish from process exit with no
  validation of the worker's task outcome. Successful process termination, valid execution,
  work completion and notification delivery need separate evidence.
- The launcher starts independent `codex exec` sessions with a generic role prompt. Its propose
  prompt does not carry the coordinator's channel reading or the required propose-then-
  specificate sequence; its prohibition on worker channel reads also skipped moderation's
  thread reconciliation and answer handling. Preserve the single inbound owner while routing
  the needed context and responsibilities explicitly.
- The quiet-tick/reporting policy and the exact-thread refusal leave the initiating user
  without the periodic progress and final result requested. **A report saved locally is not a
  delivered report**, and a missing historical thread must not erase the operator-facing
  account of current progress.

## Design direction to evaluate

Keep one accountable coordinator and serialized integration; parallel workers are an
implementation choice, not the user contract. Maintain steering responsiveness during long
work, but do not let an arbitrary five-minute boundary terminate a useful implementation.
Reuse the existing claim/worktree and GitHub evidence to recover interrupted work, refresh the
base between merges, and avoid overlapping ownership. Each pending item should have an
autonomous next action or a concrete, verified external limitation, and independent work
continues while an actual external limitation persists. Do not manufacture verification
success or bypass repository protections to make the queue appear drained.

Account for the installed Codex capabilities rather than hardcoding Claude-only
Read/ListAgents/hooks assumptions: CLI 0.153.4 supports JSONL events, schema-constrained final
output and explicit-session resume (<https://learn.chatgpt.com/docs/non-interactive-mode>).
Evaluate them for validated worker results and continuity, or pass sufficient explicit state to
a fresh worker; do not assume a separate exec session inherits the initiating chat's context or
connector, and a shell launcher cannot promise a callback into that chat without an actual
return transport. Establish a supported reporting destination, consume worker outcomes, record
delivery acknowledgement, and recover failed delivery without duplicate posts. Revalidate
plugin source availability across upgrades instead of treating an obsolete cached path and a
natural-language refusal as healthy operation. These are implementation candidates, not a
mandate for another scheduler or state framework.

## Acceptance the ask states

Demonstrate one `/work` invocation against a disposable repository carrying an existing
conflicting pull request, an undelivered finished pull request, a recoverable parked claim,
queued dependent tickets, and work longer than one tick. Without operator handoff the agent
resolves the recoverable states, runs the relevant checks, merges in order, implements the
remaining tickets and verifies the resulting base. Demonstrate interruption/restart and
plugin-cache replacement without duplicate workers or lost work. Include a worker that exits
zero while reporting it did not execute, a missing notification thread, and a failed delivery:
none may read as completed-and-notified. Verify periodic reports actually reach the selected
surface, followed by a completion report based on merged work and a fresh queue/PR
reconciliation. Exercise both the Claude Code and Codex entrypoints, not only shell return
shapes. Genuine external restrictions must be reported accurately while unrelated work
continues; ordinary conflicts and stale workflow state must be repaired by the agent.

## Handed in with the ask

The operator stated this session that they want **Codex genuinely usable, quickly** — so the
Codex entrypoint being usable end to end orders the plan.

Already repaired and open as pull request #995 (not to be re-proposed): `claim-arbitrate.sh
reap` swallowed both of its failure paths through an unconditional `continue` and answered
`{state: released, refs: []}`, byte-identical to an empty sweep, while `claim.sh` discarded the
sweep's answer and reported the resulting loss as `claim_race_lost` — one orphaned lock parked
a mission for 78 hours. The **policy** half this ask raises is untouched by that repair: a
leaked lock is still documented as a thing for a person to act on, and a lock-blocked mission
still zeroes `claimable-units.sh` so no `/implement` pass ever inspects the recovery states.
