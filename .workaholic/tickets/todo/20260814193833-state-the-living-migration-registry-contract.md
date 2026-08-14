---
created_at: 2026-08-14T19:38:33+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-workaholify-converge-the-repository-state
merge_policy:
verification_handoff: 
---

# State the living-migration registry contract

## Overview

`converge-layout.sh` composes the living migrations (`migrate-todo-owners.sh`, `migrate-ticket-states.sh`) through `/workaholify`, but the composition is a hardcoded list with no stated obligation on the next structural change: nothing tells a migration author their script must register at this seam, and nothing detects one that shipped unregistered. That is exactly how P2 left consuming repositories on a layout the plugin misreads while `/workaholify` called them conformant (issues #444, #445). State the contract in the gateway skill — `converge-layout.sh` is the single registry the command walks — and back it with a mechanical check so an unregistered migration fails the build, not a downstream repository.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policy-as-plugin` — rules ship in the plugin, enforced mechanically where syntax allows

## Key Files

- `plugins/workaholic/skills/workaholify/scripts/converge-layout.sh` — the registry; its header already states the compose-don't-reimplement rule
- `plugins/workaholic/skills/workaholify/SKILL.md` — the converge section gains the registration contract
- `plugins/workaholic/skills/gather/scripts/migrate-todo-owners.sh`, `migrate-ticket-states.sh` — the current registrants (naming convention `gather/scripts/migrate-*.sh`)
- `scripts/test-workflow-scripts.mjs` — the mechanical check's home
- `CLAUDE.md`, `plugins/workaholic/rules/workaholic.md` — the closed-layout section already registers directories in lockstep; the migration contract sits beside it

## Implementation Steps

1. Write the contract into `workaholify/SKILL.md`'s converge section: a structural change to `.workaholic/`'s shape ships its idempotent migration under `gather/scripts/migrate-*.sh` **and** registers it in `converge-layout.sh` in the same commit — mirroring the closed-layout rule's two-lockstep-sources pattern.
2. Add the mechanical check to `test-workflow-scripts.mjs`: every `gather/scripts/migrate-*.sh` is either invoked by `converge-layout.sh` or listed in an explicit in-script exclusion naming its reason; a new migration script missing from both fails the suite.
3. Seed the exclusion list with any migration that genuinely must not run at converge (none known today — the retired `migrate-strategies.sh` is deleted, not excluded).
4. Update `CLAUDE.md`'s `/workaholify` row and `rules/workaholic.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `gather/scripts/migrate-*.sh` added without a `converge-layout.sh` registration or a named exclusion fails `node scripts/test-workflow-scripts.mjs`.
- The gateway skill states the registration obligation where the converge step is documented.

**Verification method** — the commands/tests/probes that prove them:

- Add a throwaway `migrate-fixture.sh` in the test's scratch copy and assert the check fails; remove it and assert green.
- `node scripts/build-plugins/verify.mjs` for the SKILL.md edit's generated-bundle impact.

**Gate** — what must pass before approval:

- Smoke tests green; `build.mjs`/`verify.mjs` clean.

## Considerations

- The check pins machine-consumed structure (script references), not prose — consistent with the no-prose-pinning test rule.
- Migrations that need a judgment stay in `converge-layout.sh`'s REPORTED class; the contract obliges registration, not silent application.

## Final Report

Development completed as planned. `workaholify/SKILL.md`'s converge section now states
the registration obligation — a structural change ships its `gather/scripts/migrate-*.sh`
and its `converge-layout.sh` registration in the same commit — and
`scripts/test-workflow-scripts.mjs` enforces it: the new `testMigrationRegistryContract`
walks every `gather/scripts/migrate-*.sh` and fails unless each is invoked by
`converge-layout.sh` or carried in `CONVERGE_EXCLUDED_MIGRATIONS` with a reason. The
exclusion map is seeded empty, and the check asserts it bites by proving a throwaway
`migrate-fixture-registry-check.sh` would satisfy neither branch. `rules/workaholic.md`
carries the rule beside the closed-layout lockstep; `CLAUDE.md`'s `/workaholify` row was
updated in the same change.

### Discovered Insights

- **Insight**: The registry check reads `converge-layout.sh` with comment lines stripped.
  **Context**: That script's header names both migrations in prose (the APPLIED block),
  so a naive `includes()` over the whole file would pass on a migration that is only
  *documented* as composed. The same shape already appears in
  `testWorkaholifyBootstrap`, which strips comments before asserting what the bootstrap
  hook does — a script whose header documents its own contract cannot be grepped as
  evidence of that contract.

- **Insight**: The contract obliges registration, not application, and the two-way
  assertion (`composed && excluded` fails) is what keeps that legible.
  **Context**: A migration needing a judgment still belongs in `converge-layout.sh`'s
  REPORTED class, so "excluded" must mean *deliberately not run at the seam* rather than
  *not yet wired*. Allowing both states at once would let an author silence the check by
  adding an exclusion for a script the registry already composes, and the exclusion's
  reason would then describe nothing.

- **Insight**: The naming convention is scoped to `gather/scripts/`, which leaves
  `feedback/scripts/migrate-concerns.sh` deliberately outside the walk.
  **Context**: That one is a read-time record migration inside the feedback skill, not a
  migration of `.workaholic/`'s tree shape, and converging it at `/workaholify` time
  would write records in a repository the command has only just read. Widening the glob
  to every skill would pull it in and force an exclusion entry that misdescribes it.
