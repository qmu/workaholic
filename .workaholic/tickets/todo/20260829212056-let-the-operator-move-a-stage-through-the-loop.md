---
created_at: 2026-08-29T21:20:56+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-lifecycle-a-declared-stage
merge_policy:
verification_handoff: 
---

# Let the operator move a stage through the loop

## Overview

PROPOSED. The ask rules that a stage change is an **operator-auditable act, never a
machine's silent reclassification**. That rule already has a shape in this repository:
`amend.sh` is the third writer of a strategy, bounded to the parts the model calls
revisable, reached only from `/specificate`'s *changed* announcement (step 9d), matched
by **explicit slug only**, onto a pull request the publish seam itself refuses to
auto-merge (`merge_reason: strategy_touching`). The operator's merge is the authorship.

So the stage becomes the **fourth revisable part** and nothing else moves: no fourth
writer, no new route, no new refusal vocabulary. `--stage` joins `--target-date`,
`--schedule`, `--assignees` and `--aim`; the immutable half (`slug`, `type`, `status`,
`created_at`, `author`, `feedback:`) is asserted over the candidate exactly as today,
and a refusal writes nothing.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/change-control.md` — who may write what, and where the approval lives
- `workaholic:design` / `policies/data-handling.md` — one artifact, one bounded writer set

## Key Files

- `plugins/workaholic/skills/strategy/scripts/amend.sh` — gains `--stage`, validates the
  closed set with `create.sh`'s **verbatim** refusal name (`bad_stage`), appends its
  dated `## Schedule` line saying what moved, and writes nothing on any refusal.
- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 9d's invocation
  and its record-only fallbacks.
- `plugins/workaholic/skills/specificate/SKILL.md` — *Strategy lifecycle announcements*:
  a *changed* announcement may name a stage.
- `plugins/workaholic/skills/strategy/SKILL.md` — *The model*, *the third writer is
  bounded*, and the writer-set pin's stated bound.
- `scripts/test-workflow-scripts.mjs` — the pin that fails on a **fourth** writer.
- `CLAUDE.md`, `plugins/workaholic/rules/workaholic.md`.

## Implementation Steps

1. Read `amend.sh` whole, plus `strategy/SKILL.md`'s *The third writer is bounded* and
   `specificate/reference/workflow.md` step 9d whole, before writing — the bounds and
   the refusal names are the contract this extends.
2. Add `--stage <value>` to `amend.sh`'s option parse, validating against the closed set
   and reusing `create.sh`'s `bad_stage` name so one artifact never acquires two names
   for one refusal.
3. Compose the revision on the existing temporary-candidate path so a refusal leaves the
   file and the index byte-identical — no partial write, no write-then-revert.
4. Add `stage` to `revised[]` and append the existing dated `## Schedule` line naming the
   move (`進行中 → 改良中`), so the artifact carries its own stage history with **no new
   field**.
5. Extend step 9d in `reference/workflow.md` and the *changed* row in `SKILL.md`: an
   announcement naming a stage for a slug in step 5b's set reaches `amend.sh`; a closed
   direction is record-only `not_active`; an announcement naming nothing revisable stays
   `no_revision`.
6. State explicitly that a run **never** moves a stage on its own reading — a machine
   only ever carries a move the operator announced by explicit slug.
7. Update `CLAUDE.md` and `rules/workaholic.md` in the same change.
8. Extend the hermetic suite: the writer set is still exactly `amend.sh`/`close.sh`/
   `create.sh`; the pin still fails on a fourth; a stage revision lands; every refusal
   leaves the artifact byte-identical; the publish seam still refuses to auto-merge.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An announcement naming a slug and a new stage moves that field, appends one dated
  `## Schedule` line, and touches nothing else.
- `bad_stage`, `not_active` and `no_revision` each write nothing and are reported by name.
- A publish carrying the amendment reports `merged: false`, `merge_reason:
  strategy_touching` with `WORKAHOLIC_AUTO_MERGE=1` deliberately set.
- The strategy writer set is still three.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-revision`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No new writer, no new route, no new refusal vocabulary, and no path by which a routine
  moves a stage on its own reading.

## Considerations

- The tempting shortcut is a `/moderate` step that advances the stage when the evidence
  is clear. It is refused by the ask itself and by `direction-health`'s standing rule:
  that step asks and never amends.
- The stage is revisable in both directions; nothing here treats the three as a ratchet,
  because a direction that reopens is the operator's call to state.
