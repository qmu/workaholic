---
created_at: 2026-08-27T01:20:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-the-units-the-loop-already-finished
merge_policy:
verification_handoff: 
---

# Name undelivered units in backlog_all_excluded

## Overview

`backlog_all_excluded` (2026-08-26) exists so that *the queue is empty* and *the queue is full and
I can offer none of it* never render alike: it carries a **count per exclusion reason**, because a
queue emptied by claims is the protocol working while one emptied by `owned_by_other` is work
nothing can drive.

The sibling ticket adds a reason for the loop's own undelivered work. Extend the per-reason counts
with it, so an all-excluded survey names undelivered units rather than reporting a full queue and
an empty offer alike. Measured 2026-08-27: `backlog_size: 11`, `backlog: []` — hour after hour,
with the reason breakdown the only thing that could have said why.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a derived reading names its parts

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — lines ~20 and ~134–140: the
  `backlog_all_excluded` structure and its per-reason counts. Read the header paragraph recording
  why it is a *derived reading* over existing fields and adds no scan and no stored state.
- `plugins/workaholic/skills/drive/SKILL.md` — §7, where the run report renders the reading.
- `plugins/workaholic/skills/drive/reference/routing.md` — how the reading is reported per run.

## Implementation Steps

1. Read the existing derivation and confirm it is a pure reading over `backlog_size`, `backlog[]`
   and `excluded[]` — the new reason must ride the same derivation, not a parallel one.
2. Include the new reason in the per-reason counts.
3. Render it in §7's report alongside the existing reasons, in the same shape.
4. Update `drive/SKILL.md` and `CLAUDE.md`'s `backlog_all_excluded` sentence in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An all-excluded survey containing undelivered units names that reason with its count.
- The reading still adds no scan, no stored state and no field on any artifact.
- It still moves no terminal token (that is the sibling ticket's job and its scope).

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Run `plan-units.sh` over a fixture whose whole backlog is excluded by the new reason and read
  the counts.

**Gate** — what must pass before approval:

- The hermetic suite passes and existing reason counts are unchanged.

## Considerations

- Keep the reading and the token strictly separate. `backlog_all_excluded` deliberately moves no
  token, and the ticket that forbids `ok` keys on the run's own finished units, not on this count —
  merging the two would make an hourly survey reading into a completion gate.
- This ticket is only worth driving after the split lands; without a distinct reason there is
  nothing new to count.
