---
created_at: 2026-09-04T14:24:04+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-codex-loop-progress
merge_policy:
verification_handoff:
---

# Reproduce and classify Codex loop readiness failures

## Overview

Issue #974 reports that the Codex supervisor can remain alive while every useful path is
unavailable. Today `scripts/codex-loop.sh` prints its interval and log directory before the first
tick, swallows a non-zero `codex exec`, and retains only a final-message transcript. Reproduce
those states and establish one readiness vocabulary before changing startup behavior.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — degraded execution is named and inspectable

## Key Files

- `scripts/codex-loop.sh` — the supervisor that currently equates staying alive with looping.
- `plugins/workaholic/skills/work/SKILL.md` — the cross-agent contract and its stated transport limit.
- `plugins/workaholic/skills/work/reference/other-agents.md` — the measured Codex capability boundary.
- `scripts/test-workflow-scripts.mjs` — hermetic coverage for supervisor and status behavior.

## Implementation Steps

1. Reproduce the current behavior with a stubbed `codex`: a successful tick, a non-zero tick, a
   missing report, and a tick reporting `no_slack_transport` or `thread_unresolved`.
2. Measure which facts are available at the supervisor boundary and which exist only inside the
   tick's final report; do not adopt the reporter's suggested relay before this localization.
3. Define a closed readiness/result vocabulary covering ready, tick failure, report missing,
   transport absent, and work blocked, with the evidence behind each verdict.
4. Add hermetic regression rows that demonstrate the present false-ready state and pin the new
   vocabulary for the following tickets.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The fixture proves a live supervisor can coexist with a failed or transport-less tick.
- Every readiness verdict names the evidence it used and unknown never becomes ready.

**Verification method** — the commands/tests/probes that prove them:

- Run the focused supervisor fixture and `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- The failure is reproduced before startup or reporting behavior is redesigned.

## Considerations

Slack connectivity belongs to the agent session, while the shell supervisor sees only the report
returned to it. The contract must distinguish an absent transport from a refused post and from a
tick that never produced a readable result.
