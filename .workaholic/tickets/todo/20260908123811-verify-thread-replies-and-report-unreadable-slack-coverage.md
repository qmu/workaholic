---
created_at: 2026-09-08T12:38:11+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-incremental-across-messages-threads-and-mentions
merge_policy:
verification_handoff: 
---

# Verify thread replies and report unreadable Slack coverage

## Overview

Send replies through a path that accepts the real `thread_ts`, read the target thread back, and expose authorization, reachability, and API-call evidence for every intake and effect.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/` — typed read/write degradation and fallback evidence.
- `plugins/workaholic/skills/qfs-slack/` — thread reply maps and confirmation reads.
- `plugins/workaholic/skills/notify/` — exact-thread delivery semantics.

## Implementation Steps

1. Probe the selected binding's thread write map before sending.
2. Pass the exact thread coordinate and confirm the posted result in that thread.
3. Count retrieval, context, and send calls per run and distinguish estimates from measurements.
4. Emit typed unreadable, unauthorized, and unreachable outcomes without silent connector substitution.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A claimed thread reply is confirmed at the requested `thread_ts`.
- Every unavailable read range or write capability is named with its source error.

**Verification method** — the commands/tests/probes that prove them:

- Run transport fixtures for successful replies, missing maps, missing scopes, and channel membership failures.

**Gate** — what must pass before approval:

- No top-level fallback is reported as a successful thread reply.

## Considerations

Verification must not multiply reads into another full-history scan.
