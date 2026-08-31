---
created_at: 2026-08-31T11:31:18+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notice-a-periodic-artifact-that-stopped-being-produced
merge_policy:
verification_handoff: 
---

# State the cadence reading where the tick is defined

## Overview

A behaviour change updates every affected document in the same change — this
repository's own rule, with `doc-drift.sh` only a backstop. A new step, a new declaration
and a new question key each have a documented home.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step contracts and
  the finding classification table, which an unclassified step id reads as `needs_ruling`.
- `plugins/workaholic/skills/moderate/SKILL.md` — the tick's steps and its voice.
- `CLAUDE.md` — the `/moderate` row and its step count.
- `plugins/workaholic/rules/workaholic.md` — the declaration, if the first ticket put it
  there.


## Implementation Steps

1. Document the step: what it reads, what it asks, what it never does, and that it
   supplies an event only when something lapsed.
2. Classify the new step id in the finding table deliberately — an unclassified id reads
   `needs_ruling`, which is the safe default and is not the same as having decided.
3. Move the step count in `CLAUDE.md` and the skill together, so the two cannot disagree.
4. Say what did **not** move: the keys, the caps, the holds, `ask-question.sh`, the diff
   rule and every existing step.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The step is documented in the reference and the skill, and the step count matches in
  both plus `CLAUDE.md`.
- The new step id appears in the finding classification table with a deliberate value.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- `outputs/` regenerated in the same change.


## Considerations

- The step count appears in more than one sentence of `CLAUDE.md`'s `/moderate` row;
  grep for the numeral rather than trusting one edit.

