---
type: Feedback
title: Support low-context workers without stalling the work tick
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-19T09:55:01+09:00
author: a@qmu.jp
supersedes: 
---

# Support low-context workers without stalling the work tick

Source: https://github.com/qmu/workaholic/issues/1142

## Problem

In a Codex session, the operator disabled subagents because copying a long conversation into each
child consumed too many tokens. The work skill requires a coordinator that never implements inline
and never waits for workers. Applying the no-subagent preference by implementing **in the parent**
prevented the normal receipt-driven work ticks from advancing independently. Slack was still read
manually between implementation steps, but that is not equivalent to a continuously available
observation coordinator.

The operator has now explicitly allowed limited subagent use, including separate implementation
workers, and asked to restore the normal ticks. **The concern is context propagation cost, not a
categorical objection to delegation.**

## Requested behavior

- Keep Slack and feedback-issue observation on an independent, interruptible coordinator clock
  while implementation runs in workers.
- Support a **low-context dispatch mode**: launch with no inherited conversation
  (`fork_turns="none"` where supported), supplying a bounded task, relevant artifact paths,
  worktree/claim, receipt ID, current user constraints, and result schema.
- Avoid copying the entire session for every tick, reloading irrelevant worker history, or
  spawning workers merely to report unchanged state. **Expose worker count and
  context-propagation policy separately from cadence.**
- When delegation is disallowed, explicitly explain which work-loop guarantees cannot be
  maintained; retain observation if possible rather than silently replacing the coordinator with a
  long inline implementation turn.
- Preserve the coordinator instance and startup anchor when changing dispatch policy. Reconcile
  live children and receipts so resumption neither creates a second clock nor duplicates work.
- Add a regression scenario: lengthy active implementation **plus** a new Slack reply **plus**
  restricted context delegation. Verify that observation and acknowledgment continue on cadence,
  with bounded child input.

## Observed evidence and limit

The installed work skill says "never run those roles inline and never wait for them", and its
native runtime stores role cadence in receipts. In this session the parent continued
implementation under the earlier no-subagent instruction; the persisted coordinator remained
running but stopped receiving normal role ticks. Manual Slack reads continued, so the failure
should not be described as a complete Slack transport outage. No quantitative token benchmark is
claimed; the operator reported the context-copy cost as the reason for the restriction.
