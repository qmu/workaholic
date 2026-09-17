---
created_at: 2026-09-08T14:24:54+09:00
status: done
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

## Final Report

Development completed as planned.

The binding is a fenced `workaholic-slack-binding` block inside the repository's own
instruction file, read by one script (`transport/scripts/read-declared-binding.sh`) with a
stated precedence: root `CLAUDE.md`, root `AGENTS.md`, each `--scope` directory, then
`WORKAHOLIC_SLACK_BINDING_FILE`. A deeper scope overrides; two sources at one depth
disagreeing settle no value and are reported as a conflict. `/workaholify` audits it
(`check-slack-binding.sh`, advisory) and can scaffold it (`apply-slack-binding.sh`, append-only,
refusing `already_declared` with nothing written). `/infinite-development` reads it before any
Slack selection. This repository declares its own binding in a new root `AGENTS.md`.

### Discovered Insights

- **Insight**: A fenced block inside the instruction file is the only Slack-binding surface every
  agent already loads. A new `.workaholic/` area would have needed registration in two lockstep
  allowlists, and an environment variable is invisible to the portable agents this repository
  ships skills to — which is exactly how the destination became unreadable to them.
  **Context**: The same argument applies to any future cross-agent configuration: the surface
  must be one the consuming agent reads without being told to.
- **Insight**: `declared: false` had to remain an ordinary answer rather than a refusal. Every
  consuming repository today configures the channel through `WORKAHOLIC_INBOUND_SLACK_CHANNEL`
  only, so a reader that treated absence as an error would have broken all of them on the first
  tick after this landed.
  **Context**: The declaration is an authority layered above the environment, never a
  replacement for it; the environment stays the fallback and is not deprecated here.
- **Insight**: A key declared twice with two values must settle *no* value. Picking a winner by
  file order would make the loop post to a destination the operator never chose while reporting
  success, which is the exact failure the declaration exists to prevent.
  **Context**: `conflicts[]` names the key, both values and both sources, so the audit sends the
  operator to the two lines that disagree rather than to the whole file.
