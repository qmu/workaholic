---
created_at: 2026-08-27T14:24:44+00:00
status: done
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

## Final Report

Development completed as planned, and written against **what the earlier tickets shipped**
rather than what they planned — two things differ from the plan and are documented as shipped:
the survey's `refused` rows gained `landed_count` and `target_date` (the question body has to
name what landed and the date, and the useful case is a refused row), and the closure pin names
all four scripts including `create.sh`.

Five surfaces, each naming `arrived`:

- **`CLAUDE.md`** — the direction-layer bullet now reads `live | arrived | overdue | dormant |
  unreadable` with the precedence `unreadable > arrived > overdue > dormant > live`, why
  `arrived` outranks `overdue`, that it is a candidate rather than a verdict, that it lifts and
  closes no gate, and that the writer set did not move; `/moderate`'s row carries
  `direction-arrived:<slug>`; `/propose`'s row carries `quiescent` beside the other three
  readings; the drill list carries `verify-arrival`.
- **`workaholic:strategy`** — the lifecycle table gains `arrived`, the precedence line moves, and
  two paragraphs record why it outranks `overdue` and why it is a candidate.
- **`workaholic:propose`** — *Quiescent: a direction whose work is all in* (the full conjunction,
  the one term separating it from `dormant`, why it carries no date term) and *Quiescent changes
  no gate*.
- **`workaholic:moderate`** — the question key, the wording discipline it is held to, and that
  the pin covers the arrival reading too.
- **The two script headers** — both already carried the reasoning their tickets required;
  `direction-state.sh` gained the precedence rationale and `survey-strategies.sh` the date-term
  and no-gate paragraphs, so nothing was left to fill.

Also updated: `moderate/reference/workflow.md` §15 (the reading table, the fourth reading, the
body discipline, the event phrase) and `docs/loop-drill-runbook.md` (§5i and the stage table).

Verified: `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — all
built skills self-contained, policy index in sync, OKF bundle fresh;
`node scripts/build-plugins/validate-metadata.mjs` — valid and version-aligned;
`node scripts/test-workflow-scripts.mjs` — 4031 passed, 0 failed;
`bash plugins/workaholic/hooks/layout-doctor.sh .` — `conforming: true`. A grep for the old
four-state precedence returns only archived stories and archived mission/ticket bodies, which
are history and are correctly untouched.

### Discovered Insights

- **Insight**: a grep for a superseded string in this repository will hit `.workaholic/stories/`
  and `.workaholic/tickets/archive/`, and those hits are **not** drift.
  **Context**: an archived artifact records what was true when it was written. Only the living
  surfaces (`CLAUDE.md`, the skills, `rules/`, `docs/`) are the documentation rule's subject.
- **Insight**: inserting a `###` section between a section's prose and the bullet list that
  followed it silently re-parents that list.
  **Context**: `workaholic:propose`'s gates bullet list sat after the *Dormant* prose and reads
  as part of the gates discussion, not of `dormant`. The new *Quiescent* section belongs after
  it, not before.
