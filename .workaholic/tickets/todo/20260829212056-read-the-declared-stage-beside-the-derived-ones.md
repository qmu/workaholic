---
created_at: 2026-08-29T21:20:56+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-lifecycle-a-declared-stage
merge_policy:
verification_handoff: 
---

# Read the declared stage beside the derived ones

## Overview

PROPOSED. `survey-strategies.sh` emits `pace`, `overdue`, `expiring`, `dormant` and
`quiescent` on every surveyed row, eligible and refused alike, and `direction-state.sh`
composes exactly those into one lifecycle answer with a fixed precedence. The stage is a
**different kind of thing** from all of them — declared rather than derived — so it
rides beside them and **never enters that precedence**.

The two questions are stated apart, once: *what phase has the operator declared* and
*what is the evidence saying*. Folding the stage into `direction-state.sh`'s answer
would give one field two questions, which is how `overdue` was kept out of `pace` and
how `expiring` was kept out of both.

So: `stage` is carried on every survey row from `strategy/scripts/read.sh`, and
`direction-state.sh` carries it on every row too — with `state` byte-identical across
the change. This ticket makes the stage **readable**; it gates nothing.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/data-handling.md` — one reading, one derivation, one home

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — carries `stage` on
  every `eligible[]` and `refused[]` row, read once per strategy through the one reader.
- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — carries `stage` per
  row; its `state` values, its precedence and its refusals are untouched.
- `plugins/workaholic/skills/strategy/SKILL.md` — *The lifecycle state of a direction*
  gains the paragraph stating why the declared stage is beside the reading, not in it.
- `plugins/workaholic/skills/propose/SKILL.md` — the row shape.
- `scripts/test-workflow-scripts.mjs` — the byte-identity pin.

## Implementation Steps

1. Read `survey-strategies.sh`'s header whole and `strategy/SKILL.md`'s *The lifecycle
   state of a direction* whole — the precedence argument and the "one field, two
   questions" refusals are what this ticket must not undo.
2. Carry `stage` onto every survey row from `read.sh` (never a second parse of the
   frontmatter), on **refused** rows as well as eligible ones — the refused case is the
   point, since a 観察中 direction will normally be refused.
3. Carry `stage` through `direction-state.sh` per row, leaving `state`, the precedence,
   `readable`, the nulls and `--with-leaving` byte-identical.
4. Write the paragraph in `strategy/SKILL.md`: the stage is **declared**, the state is
   **derived**, neither becomes the other, and a reading may **suggest** a transition and
   never perform one. Name the refused alternative (a sixth `state` value) and why.
5. Prove the gate-neutrality mechanically: a hermetic diff of the survey's `refusal`,
   `pace`, `overdue`, `expiring`, `dormant`, `quiescent`, the sort and `selected` over a
   fixture with each of the three stages, all byte-identical.
6. Update `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every survey row, eligible and refused, carries the direction's `stage`.
- `direction-state.sh`'s `state` is byte-identical across all three stages for an
  otherwise-identical fixture.
- No gate, sort, refusal or `selected` value changes in this ticket.
- A degraded row still carries its stage — the stage is read off the artifact, not off
  the attribution walk, so an `attribution_unreadable` row is not stage-unreadable.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose`
- `sh scripts/e2e/loop-drill.sh verify-direction-health`

**Gate** — what must pass before approval:

- No sixth `direction-state.sh` value, and no reading derived from the stage here.

## Considerations

- The `stage` must not be read from the survey by `direction-state.sh`'s own second
  read — it is carried on the row the survey already emits, on `residue`'s precedent.
- A direction whose file could not be read at all reports the stage as unreadable by its
  own reason rather than defaulting to 進行中, because a default that hides a failed read
  is what `readable: false` exists to prevent.
