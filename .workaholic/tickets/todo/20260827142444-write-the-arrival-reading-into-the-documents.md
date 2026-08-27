---
created_at: 2026-08-27T14:24:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827142444-drill-the-arrival-readings-with-no-network.md
mission: say-when-a-direction-has-arrived
merge_policy:
verification_handoff: 
---

# Write the arrival reading into the documents

## Overview

PROPOSED. This repository's own rule is that a change altering behaviour updates every affected
document in the same change, and outdated documentation is a defect. Write the arrival reading into
`CLAUDE.md`, `workaholic:strategy`, `workaholic:propose`, `workaholic:moderate` and the two script
headers.

What must be recorded, in each place it belongs: what `arrived` means; why it outranks `overdue`;
that it is a **candidate** rather than a verdict; that it **lifts and closes no gate**; and that
the writer set did **not** move — `create.sh`, `amend.sh`, `close.sh`, and `close.sh` with one
caller.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `CLAUDE.md` — the strategy bullet under `.workaholic/` runtime conventions, and `/moderate`'s and
  `/propose`'s command rows.
- `plugins/workaholic/skills/strategy/SKILL.md` — the lifecycle states.
- `plugins/workaholic/skills/propose/SKILL.md` — the readings beside `pace`/`overdue`/`dormant`.
- `plugins/workaholic/skills/moderate/SKILL.md` — the `direction-health` step's question keys.
- The two script headers (`survey-strategies.sh`, `direction-state.sh`) — if the earlier tickets
  left anything unstated, it is stated here.

## Implementation Steps

1. Re-read what the earlier tickets actually shipped, and document that rather than what was
   planned — the two can differ, and the document must match the tree.
2. `CLAUDE.md`: name `arrived` in the direction-layer bullet, and add the `direction-arrived:<slug>`
   key to `/moderate`'s row.
3. `workaholic:strategy`: the lifecycle states and the new precedence.
4. `workaholic:propose`: `quiescent` beside the other three readings, and that it changes no gate.
5. `workaholic:moderate`: the new question key and the wording discipline it is held to.
6. Confirm the script headers already carry the reasoning the earlier tickets required; fill any
   gap.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every one of the five surfaces names `arrived`, and no surface still lists only four readings.
- The precedence `unreadable > arrived > overdue > dormant > live` appears wherever the old
  four-state precedence did.
- The candidate-not-verdict rule, the no-gate rule and the unchanged writer set are each stated.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- A grep for the old precedence string, returning nothing stale.

**Gate** — what must pass before approval:

- `outputs/` regenerated, so the `Outputs Freshness` CI has no diff.

## Considerations

- The temptation is to describe the design rather than the tree. Read the shipped scripts first;
  this ticket runs last for exactly that reason.
