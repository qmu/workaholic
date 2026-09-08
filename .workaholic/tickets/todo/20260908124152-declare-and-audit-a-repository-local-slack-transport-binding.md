---
created_at: 2026-09-08T12:41:52+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-incremental-across-messages-threads-and-mentions
merge_policy:
verification_handoff: 
---

# Declare and audit a repository-local Slack transport binding

## Overview

Define one repository-local transport declaration that Codex and Claude instruction surfaces can both carry, and make `/workaholify` scaffold and audit it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/` — scaffold and audit the declaration.
- `plugins/workaholic/skills/work/` — read applicable root and nested instructions before transport selection.
- `plugins/workaholic/skills/transport/` — parse the binding without assuming one instruction filename.

## Implementation Steps

1. Discover current instruction-file and Slack destination conventions across Codex and Claude hosts.
2. Define a copyable schema for workspace/team, channel name and ID, preferred QFS mount/account, expected sender, operations, and fallback order.
3. Make `/workaholify` create or audit an AGENTS.md-compatible declaration while preserving existing instructions.
4. Test root/nested precedence, missing declarations, and conflicting declarations.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Both `AGENTS.md` and supported `CLAUDE.md` instructions can declare the same binding.
- `/workaholify` reports missing or ambiguous fields without inventing identities.

**Verification method** — the commands/tests/probes that prove them:

- Run workaholify and transport parser fixtures for each instruction surface and precedence case.

**Gate** — what must pass before approval:

- A repository receives one judgeable binding schema, not host-specific parallel contracts.

## Considerations

Nested instruction precedence must follow the host's applicability rules without silently merging incompatible destinations.
