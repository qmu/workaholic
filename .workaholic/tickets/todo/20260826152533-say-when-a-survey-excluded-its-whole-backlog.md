---
created_at: 2026-08-26T15:25:33+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: drive-the-work-the-loop-wrote-one-resolution-of-who-a-person-is
merge_policy:
verification_handoff: 
---

# Say when a survey excluded its whole backlog

## Overview

PROPOSED. `plan-units.sh` already computes both numbers: `backlog_size` (what the queue holds,
before filtering) and `backlog[]` (what is offered). Measured 2026-08-26 on this repository,
they read `10` and `[]`. Nothing names that combination, so `/implement`'s run report renders
it exactly like a repository with an empty queue — and reported `ok` every hour for five days
while ten units sat undrivable.

The reading is derived from what the survey already has: no new scan, no stored state, no field
on any artifact. This ticket **reports the fact and touches no token**; whether it forbids `ok`
belongs to `refuse-ok-under-a-placeholder-identity`, which owns that table.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — computes `backlog_size`,
  `backlog[]` and `excluded[]`; its header states why each field exists. Read it whole.
- `plugins/workaholic/skills/drive/SKILL.md` §7 — the run report contract and the token table.
- `plugins/workaholic/skills/drive/reference/` — wherever the survey's fields are documented.

## Implementation Steps

1. Confirm the reading against the live numbers first: a non-zero `backlog_size` with an empty
   `backlog[]` and a populated `excluded[]` is the shape, and it is already in the output.
2. Emit it as its own named field, carrying **the count per exclusion reason** — `owned_by_other`
   is one reason among several (`claimed_active`, `claimed_reported`, `claimed_superseded`, …)
   and a reader needs to know which emptied the queue, because the answers differ.
3. Name it in `/implement`'s and `/drive`'s run reports, so "the queue is empty" and "the queue
   is full and I can offer none of it" never render alike again.
4. Follow `plan-units.sh`'s own field discipline, stated in its header: `excluded[]` names what
   the survey **saw and dropped**, and `resurveyed[]` is a top-level key rather than an
   `excluded[]` entry for exactly that reason. This is a **derived reading over** those fields,
   so it is a top-level key too — it drops nothing of its own.
5. Update the documents that describe the survey's fields in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A survey with a non-zero `backlog_size` and an empty `backlog[]` emits the reading, with a
  per-reason count.
- A survey with a genuinely empty queue (`backlog_size: 0`) does **not** emit it.
- A survey offering some of its backlog does not emit it.
- The terminal token is unchanged in every case — this ticket moves no token.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic cases over a fixture repository for all
  three survey shapes, asserting the reading and asserting the token did not move.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- No change to §7's token table in this ticket's diff.

## Considerations

- **The boundary with `refuse-ok-under-a-placeholder-identity` is the whole care here.** That
  mission owns the token table and is itself one of the stranded units. Reporting the fact is
  useful on its own and is safe to land first; taking the token as well would be two missions
  editing one table. State the boundary in the report's own wording so the next reader sees the
  fact is reported and the token deliberately is not.
- `backlog_size: 0` with everything claimed is a different, healthy state; do not fold it in.
