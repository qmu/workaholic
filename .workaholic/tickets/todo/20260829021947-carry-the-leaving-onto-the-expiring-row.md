---
created_at: 2026-08-29T02:19:47+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: warn-a-direction-before-its-date-silences-the-loop
merge_policy:
verification_handoff: 
---

# Carry the leaving onto the expiring row

## Overview

PROPOSED. `--with-leaving` attaches `closing-residue.sh`'s composition — what the
direction **never reached** (the waiting grains) and what **no direction claimed**
(the residue) — to the `arrived` and `overdue` readings. An `expiring` reading
needs the same attachment for the same reason: the person being asked to re-date
or close a direction must see, before deciding, the work of its own that never
landed and the work no direction claims.

It is **carried, never re-read**. `direction-state.sh` hands the row **back** to
`closing-residue.sh` through `--state-row`, so the lifecycle, the residue and the
waiting grains are composed exactly once — no recursion, no second assembly, and
**not one extra read of the tree or the network**. This ticket adds a reading to
that carry; it adds no reader and no call.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/single-source-of-truth.md` — one place composes the leaving, and it stays one

## Key Files

- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — the
  `--with-leaving` block and its `THE LEAVING` header, which state that the row
  goes back to the composer rather than being re-read.
- `plugins/workaholic/skills/strategy/scripts/closing-residue.sh` — the one
  place the composition lives; `--state-row` is the seam. Read its per-block
  `readable` contract before touching anything.
- `scripts/test-workflow-scripts.mjs` — the no-extra-read pin.

## Implementation Steps

1. Read `closing-residue.sh` in full, especially the per-block `readable`
   contract: each block carries its own `readable` and reason, a degraded block
   reports **null** counts, and the top-level `readable` names the source that
   failed (`waiting_unreadable:<reason>`).
2. Read `direction-state.sh`'s `--with-leaving` block and confirm how the row is
   handed back through `--state-row`.
3. Attach the leaving to an `expiring` row on exactly the path `arrived` and
   `overdue` already take — the change should be the reading's name appearing
   where those two appear, and nothing structural.
4. Confirm no extra read: the composer is reached once per row whatever the
   reading, and `--with-leaving` still makes no network call the survey has not
   already made.
5. Confirm a **degraded** leaving on an `expiring` row renders as degraded, by
   its own reason, with null counts — never as an empty leaving. A half-read
   rendered as a whole one is the collapse this layer exists to remove.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An `expiring` row under `--with-leaving` carries `leaving` with the same shape
  `arrived` and `overdue` carry.
- A degraded leaving on an `expiring` row reports `readable: false` with its own
  reason and **null** counts.
- The number of reads of the tree and of the network under `--with-leaving` is
  unchanged from before this ticket, over the same fixture.
- Without `--with-leaving`, the `expiring` row is byte-identical to ticket 3's.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the shape case, the degraded case,
  and a diff proving the reads did not grow.

**Gate** — what must pass before approval:

- The composer is not called from `direction-state.sh` a second time, and the
  step that will consume this (ticket 5) is not made to call it either.

## Considerations

- The temptation here is to compose the leaving in the consuming step because it
  is one line shorter. That is the failure `closing-residue.sh`'s header names:
  two assemblies of one fact drift. Keep the carry.
- `exhaustive` is `false` by construction on the residue, and the reading over-
  reports rather than under-reports. Do not tighten it here.
