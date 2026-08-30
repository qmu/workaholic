---
created_at: 2026-08-30T02:21:38+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-how-long-the-loop-has-been-stuck
merge_policy:
verification_handoff: 
---

# Carry the age on stalled-unit and state the two sources

## Overview

PROPOSED. `stalled-unit` and `operator-pull` each already have an **age source of their own** —
the claim tip's staleness (`WORKAHOLIC_CLAIM_STALE_HOURS`) and the pull request's own
`created_at`. Carry the tick-log age on `stalled-unit`, leave `operator-pull` reading
`created_at`, and write down **in one place** which questions read which source, so nothing
derives an age twice and the two readings cannot drift into disagreeing about one number.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh` — the `stalled-unit:<unit>`
  question; its summary already names `unknown_age`, from the **claim tip**, not the log.
- `plugins/workaholic/skills/moderate/scripts/step-operator-pulls.sh` — reads `open:<age>` from
  `publication-effect.sh`; **not modified**.
- `plugins/workaholic/skills/drive/reference/claims.md` — the one home; the source table lands
  here beside the classification ticket 7 adds.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step contracts.

## Implementation Steps

1. Attach `condition-age.sh`'s reading to each `stalled-unit` candidate as `age`, keyed on the
   `stalled-unit:<unit>` key the step already composes, and name it in `compose` beside the claim
   tip's own staleness — two distinct facts (how long the tip has not moved; how long we have
   been asking), never one presented as the other.
2. Leave `operator-pull` alone: `publication-effect.sh` stays the one reader of that age, its
   **null**-on-`unreadable` rule stays, and no tick-log reading is added there.
3. Write the source table into `drive/reference/claims.md`, one row per question naming the
   question key and the age's source: `undrivable-unit` / `retire-blocked` / `undelivered-unit` /
   `stalled-unit` read the **tick log**; `stalled-unit` **also** reads the claim tip;
   `undelivered-unit` **also** reads the pull request; `operator-pull` reads the pull request's
   `created_at` and the tick log **not at all**.
4. State the rule the table exists for: **nothing derives an age twice**, and where a question
   carries two ages they are named as two facts with their sources, never blended into one number.
5. `step-stalled-units.sh`'s summary does not move — its own header is the one that records the
   no-age-in-a-summary correctness requirement the other three steps cite.
6. No key moves; `stalled-units` still filters `superseded` and `awaiting_verification` out of its
   candidates and counts them instead, so one unit still never draws two questions.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `stalled-unit` candidates carry an `age`; the claim tip's staleness and the log age are both
  named and distinguishable in the composed question.
- `step-operator-pulls.sh` and `publication-effect.sh` are byte-identical.
- The source table in `claims.md` names every question that carries an age and its source, and the
  suite fails when a step composes an age the table does not attribute.
- `step-stalled-units.sh`'s summary is byte-identical for the same inputs.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a row parsing the table's rows and checking each
  named step against whether it calls `condition-age.sh`, both directions.
- `sh scripts/e2e/loop-drill.sh verify-operator-pulls` passes unchanged.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes; `verify-operator-pulls` passes; the operator-pull
  reader untouched.

## Considerations

- The table is prose, so it can lie. The pin (both directions — a step composing an unattributed
  age, and a table row naming a step that composes none) is what makes it a fact a change can
  lose, exactly as the proofs-and-judgements pin does for the verdict words.
- Whether `operator-pull` should *also* carry the log age is deliberately not taken: it would be a
  second number on the one question whose own source is exact and external, and the ask names it
  as the question that keeps `created_at`.

## Final Report

Development completed as planned. `stalled-unit` candidates carry `age` beside the claim tip's
own `stalled_hours`, named in `compose` as two facts with two sources.
`step-operator-pulls.sh` and `publication-effect.sh` are byte-identical. The source table lives
in `drive/reference/claims.md` and the suite checks each named step both ways.

### Discovered Insights

- **Insight**: The pin has to read the source COLUMN, not the row.
  **Context**: The `operator-pull` row's Notes say "the tick log **not at all**", so a
  whole-row `/tick log/` test reads the negation as a claim and demands that step compose an
  age. Splitting on `|` and testing the second cell is what makes the table checkable in the
  direction that matters.
- **Insight**: The two ages are visibly different on this repository right now, which is the
  mission's Experience in one line.
  **Context**: Measured on the live claim set: `batch-20260818215156` reads
  `stalled_hours: 269` with `ticks: 102` since `20260826-015129`, while
  `deploy-the-docs-site-on-merge-to-main` reads `stalled_hours: 85` with `first_seen: null` —
  stuck for three and a half days and asked about by nobody, ever. One number could not have
  said both.
