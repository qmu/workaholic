---
created_at: 2026-09-04T14:31:52+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260904143152-define-the-codex-parent-relay-contract.md, 20260904143152-return-slack-intents-from-codex-worker-ticks.md]
mission: prove-codex-loop-progress
merge_policy:
verification_handoff:
---

# Execute relayed Slack operations in the owning chat

## Overview

Teach the connector-owning main Codex conversation to consume a completed worker envelope and
perform its Slack operations in order. The parent, not the worker, executes private-inclusive
lookups, posts acknowledgements and proposal roots, and replies `Implemented` in the resolved
thread, then returns per-operation acknowledgements to the tick status.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:safety` / `policies/access-control.md` — connector authority stays in the main chat
- `workaholic:operation` / `policies/observability.md` — retries and partial delivery remain explicit

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — parent-side relay phase and tick report.
- `plugins/workaholic/skills/notify/SKILL.md` — exact thread lookup and transport selection rules.
- `plugins/workaholic/skills/work/reference/other-agents.md` — Codex-specific parent responsibilities.
- `scripts/test-workflow-scripts.mjs` — ordered execution and idempotency fixtures.

## Implementation Steps

1. Validate the worker envelope and refuse unknown or out-of-order operations before touching Slack.
2. Resolve threads through `workaholic:notify`'s existing exact-string, private-inclusive cases;
   use a supplied trigger coordinate directly when the intent carries one.
3. Execute the allowed read or write with the main conversation's connector and preserve the
   existing description-root, `Proposed`, receipt, and `Implemented` shapes byte-for-byte.
4. Record delivered, `post_refused`, `thread_unresolved`, or invalid outcomes per operation and
   feed them into the durable tick status without making notification load-bearing for work.
5. Deduplicate retries by the intent key and the existing thread contents, then test partial replay.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Every relayed operation uses the parent connector and the existing notification contract.
- Replaying a completed envelope does not create duplicate roots, receipts, or finish lines.

**Verification method** — the commands/tests/probes that prove them:

- Run a fake connector matrix plus `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- Success, refusal, unresolved thread, and partial retry are independently observable and tested.

## Considerations

Parent ownership is capability ownership, not permission to broaden scope: the relay may perform
only operations the tick already earned under `workaholic:notify`.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: Parent execution needs no second Slack implementation; the relay transports exact inputs to the existing notification rules.
  **Context**: Stable keys, ordered intents, exact/private-inclusive lookup, and read-before-replay make partial retries idempotent without storing credentials or widening post shapes.
