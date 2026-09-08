---
created_at: 2026-09-08T12:44:19+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-acknowledgements-informative-without-becoming-notification-noise
merge_policy:
verification_handoff: 
---

# Test acknowledgement facts separately from natural prose

## Overview

Reshape notification tests around semantic facts and state transitions so the agent can speak naturally without losing exact delivery, deduplication, issue, or thread guarantees.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/scripts/` — acknowledgement contract tests.
- `plugins/workaholic/skills/notify/` — structured delivery assertions.
- `plugins/workaholic/commands/infinite-development.md` — command ceiling for visible receipts.

## Implementation Steps

1. Separate semantic receipt fields from their rendered sentence in the existing fixtures.
2. Assert subject recognizability, issue mapping, actual workflow state, source reaction, and thread identity independently.
3. Add cases for captured-but-not-ready asks and grouped burst receipts.
4. Remove assertions that require one identical sentence where no protocol token depends on it.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Tests fail when a receipt omits its subject or promises a state not reached.
- Equivalent natural phrasings pass while structured delivery remains exact.

**Verification method** — the commands/tests/probes that prove them:

- Run the work, notify, and command-contract suites.

**Gate** — what must pass before approval:

- No load-bearing token is moved into unconstrained prose.

## Considerations

Keep actual protocol tokens exact; only human-facing connective prose becomes flexible.
