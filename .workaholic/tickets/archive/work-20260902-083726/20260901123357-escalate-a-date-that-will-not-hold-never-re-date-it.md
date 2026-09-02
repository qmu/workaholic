---
created_at: 2026-09-01T12:33:57+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: adjust-the-plan-hourly-not-only-report-it
merge_policy:
verification_handoff: 
---

# Escalate a date that will not hold, never re-date it

## Overview

PROPOSED. The ask says the loop should "re-date or escalate what the arithmetic says cannot
land, BEFORE the date arrives rather than when it has passed". Half of that is buildable and
half of it collides with a standing rule: a strategy is the operator's *resolved* direction,
`amend.sh` carries only a revision the operator announced by explicit slug, and **a run never
amends on its own reading**. So this ticket builds the escalation and refuses the re-dating by
name. `strategy-pace` and `direction-health` already ask about `overdue` and `expiring` — after
the date, or within a window of it. Nothing asks *before*, on the arithmetic.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-strategy-pace.sh` / `step-direction-health.sh` — the existing date questions, asked at or after the date.
- `plugins/workaholic/skills/strategy/scripts/amend.sh` — the operator's announced revision; the writer this ticket must not reach.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step spec and question contract.

## Implementation Steps

1. Read ticket 1's derivation (what remains against how long is left) and select the
   directions whose arithmetic does not clear — **before** `expiring`, which is a window
   around the date rather than a statement about the work.
2. Ask the direction's **assignee**, once per direction, carrying the numbers: what remains,
   how long is left, and that on the current rate it does not clear. Lead with what happened,
   identifier after it, one act asked — the standing question contract.
3. Key it per direction through `lib/question-id.sh` so it costs one question however many
   ticks see it, and attach the condition's age as the sibling steps do.
4. **Write nothing.** No `amend.sh` call, no `target_date` touched, no stage moved, no mission
   closed, no work held. The one act is the question.
5. Place it against the existing date questions so a direction is not asked twice about the
   same thing in one tick: this fires *before* the date; `expiring` and `overdue` keep their
   own cases. Say in the spec which fires when.
6. A direction with **no date** is never a candidate — there is nothing to escalate — and a
   degraded reading from ticket 1 yields no candidate and is named, never a guessed one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A direction whose arithmetic does not clear is asked about once, before its date.
- No strategy file is written, and `amend.sh` is not called.
- A direction already asked by `expiring`/`overdue` is not asked twice in one tick.
- A dateless or degraded direction yields no candidate and is named.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — candidate selection, the no-write assertion, and
  the overlap rule.
- The step run against a fixture board; assert the strategy files are byte-identical after.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **The ask's "re-date" is refused here, on a standing rule, and the refusal is the point.**
  A strategy is the operator's resolved direction; the loop may propose and never author.
  `amend.sh` exists precisely so a machine *carries* a revision the operator announced rather
  than making one. A loop that moves its own deadlines when it misses them is a loop whose
  dates mean nothing — which is a worse failure than the one being fixed. If the operator wants
  the loop to re-date, that is a deliberate ruling with its own measurement, and this ticket is
  where a future reader should find the argument.
- **How the operator re-dates is already one message**: announce the change naming the slug, and
  `/specificate`'s step 9d carries it through `amend.sh`. The escalation should say so, so the
  question names an act the addressee can actually take.
- Getting the *before* boundary right matters: too early and this asks about every direction
  every week, too late and it is `expiring` with extra words. Tune it against the measured day
  (three directions, same date, six days out, 30 queued) rather than by picking a number.

## Final Report

Development completed as planned, with the re-dating half refused by name, as the ticket
required. `/moderate`'s new `date-will-not-hold` step (33rd) reads `landing-arithmetic.sh`'s
`does_not_clear` rows, keeps only those `direction-state.sh` reads `live`, and asks the
direction's assignee once per direction (`date-will-not-hold:<slug>`), carrying the age. It
writes nothing: no `amend.sh` call, no `target_date`, no stage, no mission, no held work.

### Discovered Insights

- **Insight**: "Do not ask twice about the same thing" was implementable two ways, and only one
  of them is safe. Re-deriving the `expiring` boundary here (`days_to_target <= 14`) would have
  been cheaper and would have put a second copy of that constant in the tree. Reading
  `direction-state.sh`'s own `live` verdict instead means the sibling step's cases are excluded
  *by that step's reading*, so the two can never disagree — at the cost of a second attribution
  walk (36s). **Context**: the same choice recurs whenever a new question sits beside an old one.
- **Insight**: A filter that fails must not silently pass everything or silently drop everything.
  The first draft treated a refused `direction-state.sh` read as an empty live set, which asks
  nobody — safe-looking, and wrong: without the filter the step has not found *nothing to
  escalate*, it has found nothing at all. It now reports `degraded` by the reader's own reason,
  which is exactly what `direction-health` does with the same refusal.
- **Insight**: `direction-state.sh` needs an open-proposals read, so it answers
  `inbox_unreadable` in any hermetic fixture. Its callers take an optional `--open-proposals`
  file; a test that does not supply one is testing the degradation path without meaning to.
