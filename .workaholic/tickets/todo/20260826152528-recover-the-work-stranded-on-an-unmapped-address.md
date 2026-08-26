---
created_at: 2026-08-26T15:25:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826152528-read-a-person-s-addresses-through-one-script.md
mission: drive-the-work-the-loop-wrote-one-resolution-of-who-a-person-is
merge_policy:
verification_handoff: 
---

# Recover the work stranded on an unmapped address

## Overview

PROPOSED. Tickets 2 and 3 stop the strand and let a mapped alias answer `mine`. Neither
rewrites what is already written. Seven artifacts on this repository carry
`tamura.yoshiya@gmail.com` in `assignees:` — two active missions
(`refuse-ok-under-a-placeholder-identity`, `make-the-routine-create-body-documented-and-buildable`)
and five queued tickets — and a consuming repository may carry its own.

The ask requires this be a **living migration**, not a hand edit: a hand edit fixes one tree
and leaves every other repository to discover the same defect on its own.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/gather/scripts/migrate-*.sh` — the three existing living
  migrations; follow their shape, especially `migrate-todo-owners.sh`.
- `plugins/workaholic/skills/workaholify/scripts/converge-layout.sh` — the living-migration
  registry; registration lands in the **same commit** as the migration.
- `scripts/test-workflow-scripts.mjs` — carries the registry's mechanical check, which fails on
  an unregistered migration.
- `plugins/workaholic/skills/gather/scripts/identity.sh` — ticket 1's reader; the migration
  resolves through it and never parses the mapping itself.

## Implementation Steps

1. Write `gather/scripts/migrate-assignee-aliases.sh`: for every `assignees:` entry under
   `.workaholic/tickets/`, `missions/` and `strategies/`, resolve the address through
   `identity.sh` and rewrite it to the canonical address when — and only when — the mapping
   names it as an alias.
2. **Touch nothing it cannot resolve**, and report every entry it left alone by name. An
   address absent from the mapping is somebody the tree knows about and the mapping does not;
   rewriting it would be exactly the guess ticket 2 refuses.
3. Register it in `converge-layout.sh` in the same commit, per the living-migration registry
   rule. Confirm the registry's mechanical check sees it.
4. Follow the existing migrations' index discipline: **stage, never commit**, and never touch
   the caller's index beyond what the existing migrations already do.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An `assignees:` entry naming a mapped alias is rewritten to the canonical address across all
  three areas.
- An entry naming an address the mapping does not name is left byte-identical and reported.
- An entry already canonical is left byte-identical (the migration is idempotent).
- The migration is registered in `converge-layout.sh` and the registry check passes.
- A tree with no mapping file is left byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic cases over a fixture tree, including a
  second run asserting no further change (idempotence).
- On this repository: run it and confirm the seven stranded artifacts resolve to `a@qmu.jp`,
  and that `plan-units.sh` then offers them.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes, registry check included.
- A second consecutive run produces an empty delta.

## Considerations

- **A strategy's `assignees:` is the one field where empty is a refusal**, not team-owned. The
  migration rewrites an alias to a canonical address and never empties a field, so it cannot
  produce an invalid strategy — but assert that rather than relying on it, since
  `validate-strategy.sh` would otherwise reject a strategy this migration touched.
- The migration is registered to run at `/workaholify`'s converge step, so a consuming
  repository gets the recovery when it converges rather than by being told to run something.
