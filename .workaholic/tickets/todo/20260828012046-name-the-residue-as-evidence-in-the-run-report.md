---
created_at: 2026-08-28T01:20:46+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-what-the-direction-could-not-see-before-calling-it-arrived
merge_policy:
verification_handoff: 
---

# Name the residue as evidence in the run report

## Overview

`/propose` already reports `arrived` beside a proposal it made against a `quiescent`
strategy, as evidence. It now reports the residue with it, so the evidence and its limit
are read together — an `arrived` reading printed without its residue is the same partial
claim this mission is removing from the question.

Reporting only. No gate, no token, nothing proposed or withheld on it. `quiescent` lifts and
closes no gate today and does not begin to here.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — the run report's contract
- `plugins/workaholic/commands/propose.md` — the command's entry-point contract, if it names the report's fields
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — read only; the residue already rides the row
- `CLAUDE.md` — the `/propose` row, per this repository's update-the-docs-in-the-same-change rule
## Implementation Steps

1. Read `propose/SKILL.md`'s run-report contract and the sentence that makes `arrived`
   evidence rather than a verdict.
2. State that a run reporting `arrived` for a strategy also reports that strategy's residue
   — the mission slugs and the counts — and that a **degraded** residue read is reported as
   degraded and never as an empty one.
3. Keep it short. A per-row dump nobody reads is the noise this repository has twice retired
   status roots for: slugs and counts, nothing more.
4. Change no gate and no refusal. `not_active`, `not_mine`, `past_target_date`,
   `no_feedback_refs`, `work_waiting`, `open_proposal` and `attribution_unreadable` are
   untouched, and the residue is named in no gate expression.
5. Update `CLAUDE.md`'s `/propose` row in the same change.
## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A run reporting `arrived` for a strategy reports that strategy's residue beside it.
- A degraded residue read is reported as degraded, never as an empty residue.
- No gate, no sort, no `selected` and no token reads the residue.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic case asserts no script in `/propose`'s gate chain references the residue field.
- Reading the shipped `propose/SKILL.md` and `CLAUDE.md` shows the reporting obligation stated.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- The documents are updated in the same commit as the behaviour.

## Considerations

- The reporting surface is a run report an hourly routine writes, read by nobody on the day
  it matters — which is exactly why the **question** in the previous ticket is the primary
  delivery and this is evidence beside a decision already made.