---
created_at: 2026-09-08T12:33:03+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: turn-quiescent-blockers-into-mature-decisions-and-resume-work
merge_policy:
verification_handoff: 
---

# Judge whether a human decision is mature enough to block

## Overview

Introduce the decision-maturity judgment before a loop observation can become a human gate. The judgment must name missing business, design, data, or operational premises and select defer, retire, prerequisite planning, or ask-now.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/` — derive and render decision-ready blockers.
- `plugins/workaholic/skills/propose/` — expose why an evolutionary move cannot proceed.
- `plugins/workaholic/rules/workaholic.md` — keep the maturity and origination responsibilities in one model.

## Implementation Steps

1. Trace how `quiescent`, `no_evolutionary_move`, and existing decision questions are currently derived and deduplicated.
2. Define one maturity verdict with explicit outcomes for ask-now, defer, retire, and prerequisite planning.
3. Carry the verdict and its evidence into moderation without turning every observation into a gate.
4. Cover mature and immature examples in the routine suites.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Premature or meaningless questions cannot block a strategy.
- Each deferred question reports the premise or planning work it lacks.

**Verification method** — the commands/tests/probes that prove them:

- Run the propose and moderate script suites with fixtures for each verdict.

**Gate** — what must pass before approval:

- Existing quiescent and no-move readings remain observations and all maturity cases are deterministic in tests.

## Considerations

The maturity decision is a model judgment; its evidence and outcome must remain visible and arguable rather than hidden in a score.
