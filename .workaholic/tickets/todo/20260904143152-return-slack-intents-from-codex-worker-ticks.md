---
created_at: 2026-09-04T14:31:52+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260904143152-define-the-codex-parent-relay-contract.md]
mission: prove-codex-loop-progress
merge_policy:
verification_handoff:
---

# Return Slack intents from Codex worker ticks

## Overview

Change the Codex worker side of a tick to return structured Slack read/write intents to its
connector-owning parent. A worker with no connector must describe the required operation and its
own progress honestly; it must not attempt OAuth, silently discard the post, or report an intent
as a delivered notification.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:safety` / `policies/access-control.md` — workers never receive parent credentials
- `workaholic:operation` / `policies/observability.md` — each intent and outcome remains attributable

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — worker behavior at every tick stage.
- `plugins/workaholic/skills/notify/SKILL.md` — allowed operations and byte-stable message shapes.
- `scripts/codex-loop.sh` — capture of the worker's structured final result.
- `scripts/test-workflow-scripts.mjs` — worker result and failure fixtures.

## Implementation Steps

1. Make the Codex substitution distinguish a connector-less relayed worker from an autonomous
   session that truly has no report path.
2. Emit ordered read, acknowledgement, proposal, and implementation intents using the relay
   contract, preserving exact lookup tokens, channel, thread coordinates, and message text.
3. Include `/implement` and `/propose` outcomes, blocked reasons, and the next due time beside the
   intents so the parent can report one complete tick.
4. Keep credentials, connector calls, fuzzy thread matching, and locally invented notification
   shapes out of the worker path.
5. Cover zero-intent, multi-intent, blocked, malformed, and interrupted worker results.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A connector-less worker can complete a tick with actionable intents and an honest outcome.
- No worker result says Slack was notified before a parent acknowledgement exists.

**Verification method** — the commands/tests/probes that prove them:

- Run worker fixtures with a stubbed `codex` and `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- Worker output validates against the relay contract for every notification-producing tick path.

## Considerations

The no-connector token script remains a valid transport under `workaholic:notify`; this ticket
changes only the Codex scheduled-worker path whose parent is expected to own a richer connector.
