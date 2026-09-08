---
created_at: 2026-09-08T14:24:54+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-honor-its-declared-binding-and-complete-thread-coverage
merge_policy:
verification_handoff: 
---

# Declare and audit the repository Slack binding

## Overview

Define one repository-local Slack binding for portable agent instructions and make `/workaholify`
scaffold or audit it without assuming that every agent reads `CLAUDE.md`.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/` — schema and reader for the declared binding.
- `plugins/workaholic/skills/workaholify/` — scaffold and audit the binding for consuming repositories.
- `plugins/workaholic/commands/infinite-development.md` — require the binding read before Slack selection.

## Implementation Steps

1. Inventory the current environment-only workspace/channel inputs and instruction-file assumptions.
2. Define a copyable binding carrying workspace/team, channel name and ID, preferred QFS mount and account/profile, expected sender identity, required operations, and fallback order.
3. Read the binding from applicable repository instructions, supporting `AGENTS.md` and the environment's native instruction surface without duplicating policy.
4. Extend `/workaholify` setup and checks so a missing, partial, or contradictory binding is reported before loop startup.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- One binding expresses destination, credential preference, sender identity, operations, and fallback order without agent-specific ambiguity.

**Verification method** — the commands/tests/probes that prove them:

- Run focused schema, instruction-discovery, and `/workaholify` fixture tests for `AGENTS.md`, `CLAUDE.md`, missing declarations, and nested overrides.

**Gate** — what must pass before approval:

- A consuming repository can copy, validate, and audit the binding before any Slack effect.

## Considerations

Repository instructions remain authoritative; setup may append a missing section but must not rewrite an operator's existing document.
