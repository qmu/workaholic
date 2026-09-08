---
created_at: 2026-09-08T14:24:54+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-honor-its-declared-binding-and-complete-thread-coverage
merge_policy:
verification_handoff: 
---

# Preserve typed fallback and revalidate Slack effects

## Overview

Permit connector fallback only after a typed QFS capability, authorization, availability, or
reachability failure, preserving the declared destination and thread while naming the degraded route and sender evidence.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/scripts/perform.sh` — enforce operation-specific route eligibility and revalidation.
- `plugins/workaholic/skills/transport/scripts/adapters/` — normalize QFS and connector failures without destination drift.
- `plugins/workaholic/skills/work/` — report startup and effect-time degradation in the originating loop.

## Implementation Steps

1. Enumerate the typed failures that may move an operation from QFS to a connector and refuse every untyped switch.
2. Carry workspace, channel ID, thread timestamp, and expected sender through fallback resolution and delivery evidence.
3. Revalidate when the binding changes or QFS fails before an effect, without treating connector success as proof of preferred-route configuration.
4. Test successful QFS effects, each permitted fallback class, preserved thread delivery, unknown sender identity, and retry reconciliation.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Every fallback names the exact QFS failure and never changes the bound channel or thread silently.

**Verification method** — the commands/tests/probes that prove them:

- Run transport protocol fixtures across QFS success, unavailable capability, authorization failure, channel reachability failure, and connector fallback.

**Gate** — what must pass before approval:

- A successful connector effect remains explicitly degraded and cannot certify the preferred QFS sender.

## Considerations

Effect retries must keep the stable request ID and reconcile unknown delivery before any resend.
