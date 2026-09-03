---
created_at: 2026-09-03T07:17:26+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: pay-only-the-operative-cost-on-every-tick
merge_policy:
verification_handoff: 
---

# Deliver a subagent result to the parent once

## Overview

A run's result reaches the parent twice. Measured once in this session: a `/moderate` run
delivered its report as a summary message and as an idle notification carrying substantially the
same content — a thirty-one step table, twice, into the parent's context. The idle notification
always arrives; the summary is the duplicate.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §2 ends the turn and §3 reports; the
  parent's contract with its subagents lives here
- `plugins/workaholic/skills/loops/SKILL.md` — states that results arrive as task notifications
- `plugins/workaholic/commands/moderate.md` — the run whose report was measured doubled

## Implementation Steps

1. Establish which of the two deliveries the tick controls: the notification is the harness's
   and always arrives, so the removable one is the subagent's own summary back to the parent.
2. State in the command that a spawned run's result reaches the parent through its task
   notification and that the tick neither asks for nor repeats a summary.
3. Say what a run's own final message should therefore be: short enough that arriving twice
   would not matter, since the tick cannot suppress the notification.
4. Leave §2's *do not poll, do not await, do not summarise their work* untouched — this is the
   same rule, and the ticket makes it reach the subagent side as well as the parent's.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A run's result reaches the parent once.
- The tick still never polls, awaits or summarises a subagent's work.

**Verification method** — the commands/tests/probes that prove them:

- Read `commands/infinite-development.md` §2 and §3 against the two conditions.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- Nothing is asserted about the harness's notification that the repository cannot control.

## Considerations

If the doubled delivery turns out to be entirely the harness's, the honest outcome is to say so
in the command and change nothing — a ticket that reports the measurement was wrong is a real
outcome, not a failure.

## Final Report

**Outcome**: implemented.

The spawn section now states that **a run's result reaches the parent once**: the idle notification
always arrives, so a subagent must not also be asked for a summary message.

**Which of the two survives was decided on a property, not a preference**: the notification is the
one that cannot be turned off, so it is the one that stays and the summary is the duplicate. The
measurement is recorded beside it — a thirty-one step table delivered twice into the parent's
context, both carrying substantially the same content.

**Verified**: `node scripts/test-workflow-scripts.mjs` asserts the rule is present in the ceiling.
