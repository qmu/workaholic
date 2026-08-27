---
created_at: 2026-08-26T15:25:28+00:00
status: done
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

## Final Report

Development completed as planned, with one part of the verification deliberately left to the
operator — stated below rather than worked around.

`gather/scripts/migrate-assignee-aliases.sh` rewrites an `assignees:` entry the mapping names
**as an alias** onto that entry's canonical address, across `tickets/`, `missions/` and
`strategies/`, resolving through `identity.sh` and never parsing the mapping itself. It
touches nothing it cannot resolve and reports every such address by name; an already-canonical
entry is left byte-identical, so a second consecutive run is an empty delta; a tree with no
mapping file comes out byte-identical, because `identity.sh` is the identity function there.
It stages and never commits, and touches nothing in the caller's index beyond the files it
rewrote. It is registered in `converge-layout.sh` in this same commit and the registry's
mechanical check sees it (`testMigrationRegistryContract` walks the naming convention).

A strategy's `assignees:` is the one field where empty is a refusal rather than team-owned;
the migration rewrites an alias onto a canonical address and never empties a field, and the
suite asserts that rather than relying on it.

**What is not verified here, and why.** The ticket's second verification — *run it on this
repository and confirm the seven stranded artifacts resolve to `a@qmu.jp`* — cannot pass until
`.claude/git-identities` names `tamura.yoshiya@gmail.com` as an alias of `a@qmu.jp`. Run here,
the migration reports `migrated: 0` with `unresolved: [noreply@anthropic.com,
tamura.yoshiya@gmail.com]` — correct behaviour, and exactly the report it is designed to
produce. Writing that mapping line is an assertion that two addresses are one person, and this
mission's own tickets rule that out for an unattended path: *whether an address belongs to a
person is a human's ruling, so an unattended path must never write one unaided*. So the
recovery is complete as **mechanism** and pending as **data**, and the mission routes that one
line to the operator through the two surfaces built beside it — `/workaholify`'s coverage audit
proposes it with the address already filled in, and `/moderate`'s `undrivable-units` step asks
about it once. The seven artifacts resolve the moment the line lands, with no further code.

### Discovered Insights

- **Insight**: `noreply@anthropic.com` — the container's placeholder identity — appears in this
  tree's `assignees:` on six artifacts, and the migration reports it beside the real stranded
  address.
  **Context**: it is genuinely uncovered and genuinely should not be mapped, which is a useful
  proof that "report, never rewrite" is the right default: a migration willing to guess would
  have had to invent an owner for a placeholder.

- **Insight**: the migration rewrites only the frontmatter's first `assignees:` line, matched
  the way `read-assignees.sh` matches it, so a body line beginning `assignees:` is prose and
  stays prose.
  **Context**: `.workaholic/` artifacts routinely quote frontmatter keys in their own text —
  this very ticket does — so a whole-file substitution would corrupt the documents that
  describe the field.
