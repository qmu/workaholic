---
created_at: 2026-08-29T04:21:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-s-own-findings-become-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Classify a finding as repairable or needing a ruling

## Overview

PROPOSED. The classification is the mission's whole safety property: a finding whose
repair is **mechanical** may become work with no person asked, and a finding needing
a human **ruling** must keep asking exactly as it does today. Derive it from the
**step id** each step already emits — `run.sh`'s `STEPS` list is the closed
vocabulary — so no artifact gains a field, no second vocabulary is created, and no
store is added.

One closed table in one place, keyed on the step id, in the shape
`drive/reference/claims.md`'s *Proofs and judgements* already uses: prose plus a pin,
never a classifier function that would be a second derivation of the same fact. An
**unclassified step id defaults to `needs_ruling`** — mislabelling a ruling as
mechanical is the failure the classification exists to prevent, so the default is the
safe side and a new step is silent until somebody classifies it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/access-control.md` — the machine acts only where no human ruling is owed

## Key Files

- `plugins/workaholic/skills/moderate/reference/workflow.md` — the table's home, beside
  the step contracts it keys on; one home, so nothing assembles it twice.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — `STEPS` is the closed step-id
  vocabulary the table is keyed on; read it, never restate it.
- `plugins/workaholic/skills/moderate/scripts/lib/question-id.sh` — the existing single
  derivation of a question id from a key; the classification reads the **step id**, and
  this file is where that derivation already lives.
- `scripts/test-workflow-scripts.mjs` — pins the table against `STEPS`.

## Implementation Steps

1. Read `run.sh`'s `STEPS` and `moderate/reference/workflow.md`'s per-step contracts,
   and read `drive/reference/claims.md`'s *Proofs and judgements* for the table shape
   that is already pinned rather than inventing one.
2. Write the table in `moderate/reference/workflow.md`: one row per step id that files,
   each `repairable` or `needs_ruling`, each with the reason in one clause. Start from
   the ask's own examples — `retire-claims` (a branch CI could not delete),
   `inbound-sweep` (a diverged channel default), `merge-conflicts` / `stuck-prs` (a
   pull request conflicting with `main`) are `repairable`; `standing-rulings`,
   `undrivable-units` and `direction-health` are `needs_ruling` by their own contracts.
3. State the default in the table's own header: **an unclassified step id is
   `needs_ruling`**, and say why in one sentence.
4. Pin it: the suite fails when a `STEPS` entry is absent from the table **and** when
   the table names a step id `STEPS` does not, so the two cannot drift.
5. Do not add a `classify.sh`. The table is read by ticket 3's step and by nothing else;
   a function returning the answer would be the second derivation this refuses.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every step id that can file carries exactly one classification, in one place.
- An unclassified step id reads `needs_ruling`, stated in the table itself.
- No artifact gained a field and no new store exists.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the drift pin over `STEPS` × table.
- A scratch step id added to `STEPS` and not to the table makes the suite fail.

**Gate** — what must pass before approval:

- The suite is green, and both halves of the drift pin were shown to fail deliberately.

## Considerations

- The tempting widening is to classify by *severity* rather than by *who must act*.
  Refuse it: the question is whether a person owes a ruling, and a severe mechanical
  repair is still mechanical.
- `merge-conflicts` is the row most worth arguing about — resolving a conflict on a
  claimed branch is nobody's job here (`workaholic:drive`). If the reading is that the
  repair is *not* mechanical, classify it `needs_ruling` and say so; the default is on
  that side for exactly this reason.
