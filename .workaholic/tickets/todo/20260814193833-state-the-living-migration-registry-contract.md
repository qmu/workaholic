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
