---
created_at: 2026-08-13T11:26:19+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260813112619-fold-abandoned-and-icebox-tickets-into-the-archive.md
mission: revive-strategy-and-reshape-the-workaholic-artifact-set
merge_policy:
---

# Apply the layout migrations through workaholify

## Overview

PROPOSED. Issue #436 closes with the seam: "these migrations need to be applied through `/workaholify`". The four preceding tickets change the shape of `.workaholic/` — a registered `strategies/` area, a feedback record with a subject, three areas removed from the closed layout, and a two-state ticket tree. In this repository each lands with its own migration. In every *consuming* repository the plugin updates first and the tree does not follow, and because the layout is enforced (`validate-ticket.sh` denies a write into an unregistered directory, and the new ticket floor denies the retired states) an un-migrated repo does not degrade — its next ticket write is blocked with a reason that describes a shape it has never had.

`/workaholify` is the command that wires a repository to the standards and already checks the web bootstrap, audits `CLAUDE.md`, surveys routines and confirms the working-directory guard. This ticket adds the layout convergence to that list: run the living migrations, report what moved, and name what a human must decide.

## Policies

- `workaholic:operation` / `policies/delivery.md` — a migration that ships to other repositories is a delivery path and needs its own confirmation
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`, idempotent, no network
- `workaholic:implementation` / `policies/recovery.md` — a partial migration must leave a repository readable and re-runnable, never half-shaped
- `workaholic:implementation` / `policies/objective-documentation.md` — the command's contract row states the new step

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — the audit's step list; the layout convergence joins it with its report shape.
- `plugins/workaholic/skills/workaholify/scripts/` — where the runner lives; it composes the per-change living migrations rather than reimplementing them.
- `plugins/workaholic/hooks/layout-doctor.sh` — the read-only audit that says whether a tree conforms; it is the before/after probe of the convergence.
- `plugins/workaholic/skills/mission/scripts/lib/resolve.sh` and `gather/scripts/migrate-todo-owners.sh` — the existing living-migration seam and its precedent for idempotent, best-effort convergence.
- `plugins/workaholic/commands/workaholify.md` — the thin alias whose contract sentence changes.
- `CLAUDE.md`, `README.md` — the `/workaholify` contract row in the commands table.
- `scripts/test-workflow-scripts.mjs` — hermetic cases over a fixture repository in the old shape.

## Implementation Steps

1. Enumerate the migrations this mission produces (strategies area registration, feedback subject floor, three-area retirement, ticket-state fold) and give each a single idempotent entry point.
2. Add the convergence step to `/workaholify`: run `layout-doctor.sh` first, run each migration, run it again, and report the delta — what moved, what was already converged, what could not be decided.
3. Keep it non-destructive by contract: anything requiring a judgment (content the three-area retirement did not decide for that repo, a ticket whose state is ambiguous) is **reported, never guessed**, exactly as `/workaholify`'s existing audit reports rather than rewrites.
4. Make the run safe to repeat: a converged repository produces an empty delta and no commits.
5. Update the command's contract row, the SKILL, and the docs in the same change.
6. Argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Open Decisions

Resolve explicitly while driving and record the resolution in the Final Report.

- **Does `/workaholify` commit the migration, or leave it staged for the operator?** The command is attended and its other steps report rather than write; a migration that commits changes that posture, while one that only stages leaves a repository in the blocked state until someone finishes it.
- **What happens in a repository that has content in the three retired areas?** The retirement ticket decides this repository's answer; whether the same answer is imposed elsewhere or offered as a report is a separate call.

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- `/workaholify` converges a fixture repository in the pre-mission shape to the post-mission shape, and reports each change.
- A second run reports an empty delta and changes nothing.
- Anything needing a human decision is reported with the decision named, never silently resolved.
- `layout-doctor.sh` reports `conforming: true` on the fixture after the run.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with fixtures for the old shape, the converged shape, and the ambiguous case.
- `bash plugins/workaholic/hooks/layout-doctor.sh <fixture>` before and after.
- `node scripts/build-plugins/build.mjs` then `verify.mjs` and `validate-metadata.mjs` green with `outputs/` committed.

**Gate** — what must pass before approval:

- Suite, build/verify and layout-doctor green, plus an in-session demo of the convergence on a throwaway repository and of the empty second run.

## Considerations

- This ticket is last by construction: it can only carry migrations that exist, so it lands after the four that produce them.
- The measured risk it exists to remove is a repository blocked by its own enforcement — the plugin's floor is unconditional and has no env-var opt-out, so convergence is the only way out.
