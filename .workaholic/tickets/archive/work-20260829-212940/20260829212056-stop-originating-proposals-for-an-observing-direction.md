---
created_at: 2026-08-29T21:20:56+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-lifecycle-a-declared-stage
merge_policy:
verification_handoff: 
---

# Stop originating proposals for an observing direction

## Overview

PROPOSED. This is the first ticket in the mission where the stage **does** something.
The ask: 観察中 means the development has settled and the loop stays **reactive only** —
it responds when log observation finds an error or a user files feedback, and no longer
originates proposals for that direction on its own.

`/propose` is the one routine that originates work, and its brake is a list of
mechanical, derived gates each reported by name (`not_active`, `not_mine`,
`past_target_date`, `no_feedback_refs`, `work_waiting`, `open_proposal`,
`attribution_unreadable`). A stage of 観察中 becomes one more: **`observing`**.

It qualifies as a gate on that list's own terms — it is read off the artifact, it is not
a judgement the running session can make differently, and it is reported by name. It is
the first gate that is **declared** rather than derived, which is exactly what makes it
safe: no machine's reading silences a direction, only the operator's own word.

**Reactive work still reaches the direction.** 観察中 stops `/propose` from
*originating*; it stops nothing else. An inbound ask — a Slack message the `:40` sweep
captures, an issue a person files, an error somebody reports — still becomes an `[FB]`
issue, still reaches `/specificate`, and still lands as a mission or a ticket carrying
that direction's refs. That asymmetry is the whole point of the stage.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/change-control.md` — what may silence an automated actor

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the `observing`
  refusal, placed in the ladder and argued against its neighbours.
- `plugins/workaholic/skills/propose/SKILL.md` — the gate list and what the refusal means.
- `plugins/workaholic/skills/specificate/SKILL.md` — the statement that a 観察中 direction
  still receives inbound work, so the asymmetry is written where the writer reads.
- `plugins/workaholic/skills/strategy/SKILL.md` — the stage's behavioural consequence.
- `CLAUDE.md`, `plugins/workaholic/rules/workaholic.md`.

## Implementation Steps

1. Read `survey-strategies.sh`'s gate block whole — every gate carries an argument for
   why it reduces proposals, and this one owes the same.
2. Add `observing` to the refusal ladder, keyed on the stage the previous ticket carries
   onto the row. Place it **after** `not_active` and `not_mine` (a closed or foreign
   direction is not this repository's question) and **before** `past_target_date`: an
   observing direction that is also overdue should read as observing, because that is the
   fact a person acts on and lateness on a settled direction is not a failure.
3. Argue that placement in the header, both neighbours named, as `expiring`'s ranking is
   argued.
4. Leave `pace`, `overdue`, `expiring`, `dormant`, `quiescent`, `residue` and the sort
   **byte-identical**: the readings are evidence and stay emitted on a refused row, which
   is what lets a 観察中 direction still be seen.
5. State in `propose/SKILL.md` that `observing` is the **first declared** gate and why
   that is admissible where a derived silence was refused (`pace` gates nothing; a
   machine's guess must not silence the one routine that originates work — the operator's
   own word is not a guess).
6. State in `specificate/SKILL.md` that the stage gates **origination only**: an inbound
   ask against a 観察中 direction is judged and emitted exactly as before.
7. Update `CLAUDE.md` and `rules/workaholic.md` in the same change.
8. Extend the hermetic suite and `verify-propose`: a 観察中 direction is refused
   `observing` and opens no issue; a 進行中 and a 改良中 one propose exactly as today.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A direction declared 観察中 is refused `observing` and `/propose` opens no issue for it.
- A direction declared 進行中 or 改良中, or carrying no stage at all, produces a survey
  row byte-identical to today's.
- The refused 観察中 row still carries `pace`, `overdue`, `expiring`, `dormant`,
  `quiescent` and its `residue`.
- `/specificate` emits work for a 観察中 direction from an inbound ask, unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose`
- `sh scripts/e2e/loop-drill.sh verify-specificate`

**Gate** — what must pass before approval:

- No derived reading gains the power to silence a direction; only the declared field does.
- Nothing about the inbound path is narrowed.

## Considerations

- The failure mode to watch is a direction parked in 観察中 that nobody revisits. It is
  covered by the transition question rather than by a timer: a timer would re-open a
  direction the operator settled, which is the silent reclassification the ask forbids.
- `no_evolutionary_move` stays what it is — an honest empty answer for a direction the
  run had nothing to propose against — and is never rendered as `observing`.

## Final Report

Development completed as planned.

`observing` joins the refusal ladder after `not_active` and `not_mine` and before
`past_target_date`, keyed on the stage the previous ticket carries onto the row. Both
placements are argued in the script header against their neighbours. `pace`, `overdue`,
`expiring`, `dormant`, `quiescent`, `residue` and the sort are untouched, and the refused row
carries all of them so a settled direction stays visible.

### Discovered Insights

- **Insight**: the previous ticket's "the stage gates nothing" test failed the moment this
  gate landed — correctly, and that is the useful signal rather than an inconvenience. The
  assertion was narrowed to the two values that still gate nothing, with 観察中 named in place
  as the one deliberate exception and its behaviour asserted by this ticket's own test.
  **Context**: a byte-identity pin written across a whole value set becomes a liability the
  moment one member of that set is meant to differ. Narrowing it and naming the exception
  keeps the guarantee precise — *the stage gates nothing except the one value the operator
  declares to mean stop* — where exempting the value silently would have left a pin that no
  longer says anything.

- **Insight**: the ladder's ordering is testable rather than merely arguable. A direction that
  is 観察中 **and** overdue, one that is 観察中 **and** closed, and one that is 観察中 **and**
  foreign each pin one adjacency, so the placement argument in the header is checked by three
  assertions instead of being prose a later change can quietly invalidate.
