---
created_at: 2026-08-17T11:45:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817114536-diagnose-the-release-note-automation-drift.md
mission: correct-the-release-note-automation-to-its-intended-design
merge_policy:
verification_handoff: 
---

# Derive the deploy target environment mapping

## Overview

Expected action 1 of the ask, and the precondition for everything after it: survey the
`deployments/` area and establish which deploy targets exist and which software environment
each corresponds to. Per-target note generation cannot start before that mapping is known.

The area already carries the fields this needs (`environment`, `confirmation_method`,
`command`, and optionally `paths:`), and it already has a hard rule this ticket must not
break: **a human writes a deployment record; `/ship` is the only live reader and never a
writer.** So "derive the mapping" means *read what is declared, report what is missing, and
give a human a way to fill it* — never generate a target record from the repository's
shape. That distinction is the whole design of the area, and this ticket is where it would
be easiest to lose.

## Policies

- `workaholic:operation` / `policies/delivery.md` — a delivery path is declared, not inferred
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:operation` / `policies/observability.md` — a missing declaration is reported by name, never defaulted

## Key Files

- `.workaholic/deployments/README.md` — the area's definition, including the two deploy
  models and the *who writes it* rule.
- `.workaholic/deployments/marketplace.md` — this repository's single target: `environment:
  production`, `confirmation_method: other`, deploy-on-merge, no `paths:`.
- `plugins/workaholic/skills/ship/scripts/read-deployments.sh` — the existing reader; extend
  it rather than adding a second parser of the same frontmatter.
- `plugins/workaholic/skills/ship/scripts/read-deploy-state.sh` — where `paths:` and
  `attribution` already decide what counts as unreleased for a target.
- `plugins/workaholic/skills/report/scripts/area-freshness.sh` — the area's upkeep seam; it
  reports and never writes, and it is the precedent for this ticket's posture.
- `plugins/workaholic/rules/workaholic.md` — the area table and its definitions.

## Implementation Steps

1. Extend the reader to emit the mapping explicitly: per target, its environment, its deploy
   model, its `paths:` (or the `whole_range` default), its confirmation method, and whether
   each is declared or defaulted.
2. Report what is **not** derivable: a repository with no `deployments/` record at all, a
   target whose environment is unstated, a component in the tree that matches no target.
   Each is a named gap, not an empty result.
3. For the undeclared case, produce a **scaffold a human can fill** — a template record with
   the fields blank and the reasoning prompts inline — and stop there. Do not write a
   populated record from the repository's shape: that would make the next `/ship` gate on a
   machine's guess about how production is reached.
4. Add the mapping to `report-deploy-status.sh`'s output so the existing status read gains
   the per-target axis without a second command.
5. Update the area's README with the mapping's shape and where it is consumed.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The mapping is emitted per target with every field marked declared or defaulted.
- A repository with zero deployment records yields a named gap and a scaffold, never a
  generated record.
- No code path writes a populated deployment record.
- `read-deployments.sh` remains the single parser of that frontmatter.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/ship/scripts/read-deployments.sh`
- `node scripts/test-workflow-scripts.mjs`
- A run against a throwaway repository with no `deployments/`: gap reported, scaffold
  offered, nothing written.

**Gate** — what must pass before approval:

- The human-writes-it rule is demonstrably intact.

## Considerations

- This repository has exactly one target, so the mapping is nearly trivial here. Build and
  test it against a synthetic multi-target fixture, or it will encode the single-target
  case as the shape of the world.
- `paths:` is the field that decides whether a target's own note commits count as
  unreleased. It is optional today; the note-generation ticket depends on it, so this
  ticket should make its absence loudly visible.
