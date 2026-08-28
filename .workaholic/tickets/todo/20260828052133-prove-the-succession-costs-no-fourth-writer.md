---
created_at: 2026-08-28T05:21:33+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-end-a-turn-of-the-loop-not-its-stop
merge_policy:
verification_handoff: 
---

# Prove the succession costs no fourth writer

## Overview

The succession's whole premise is that it costs no new writer, no new relation and no field.
That is a property a later change can silently lose, so pin it: the attribution must be readable
through the succession, and the suite must fail if the carry reaches `create.sh` or if a fourth
writer of the strategy artifact appears.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the writer-set pin and the new assertions
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — read over a successor
- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — the successor's first reading
- `plugins/workaholic/skills/feedback/scripts/ask-feedback-line.sh` — the wiring point the pin names

## Implementation Steps

1. Assert that `attributed-work.sh` over a successor returns the predecessor's landed work and its
   residue, through the existing citation and with no new relation.
2. Assert that `direction-state.sh` reads a fresh successor `live` rather than `dormant` — a
   direction born carrying its predecessor's refs is not one nothing is answering.
3. Extend the existing writer-set pin so it still fails on a fourth writer of the strategy
   artifact, with the succession in the tree.
4. Add the sharper pin: fail if the carry is wired into `create.sh` instead of the ask line.
5. Assert that no artifact gained a field and that the retired `strategy:` relation is still
   absent.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `attributed-work.sh` over a successor returns the predecessor's landed work and residue
- `direction-state.sh` reads a fresh successor `live`
- The suite fails on a fourth writer of the strategy artifact
- The suite fails if the carry is wired at `create.sh` rather than the ask line

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- Each new assertion is proved to fail when its property is broken, not merely to pass today

## Considerations

- A pin that cannot fail is not a pin; each assertion needs its own deliberately broken fixture.
