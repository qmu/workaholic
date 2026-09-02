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

# Say which directions the arithmetic says cannot land

## Overview

PROPOSED. The reading landed already: `/standup`'s digest names each direction, the missions
serving it, each mission's acceptance `checked`/`total`, its queued count and the whole queue.
What nobody does is the **arithmetic over it** — 30 queued tickets against three directions all
dated the same day, six days out, and no reading anywhere said that will not land. This derives
that answer from the reading that exists: per direction, what remains against how long is left.
Evidence for the four tickets after it, and a verdict for nobody.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/standup/scripts/digest.sh` — already composes per direction its missions, acceptance and queued counts; the reading this derives over.
- `plugins/workaholic/skills/strategy/scripts/survey-strategies.sh` — supplies `pace`, `days_to_target`, `overdue`, `expiring`.
- `plugins/workaholic/skills/strategy/scripts/` — home for the new derivation.

## Implementation Steps

1. Read what already exists before adding anything: `digest.sh`'s `missions[]` (title,
   acceptance `checked`/`total`, queued), `queued_total`, and `survey-strategies.sh`'s
   `days_to_target` and `pace`. Confirm the inputs are all present, so this composes rather
   than walks.
2. Add one derivation answering, per direction: **what remains** (unchecked acceptance items
   and queued tickets across its missions) against **how long is left** (`days_to_target`).
   Compose the existing readers; add no second walker, no relation, and **no field on any
   artifact**.
3. Answer in the repository's existing degradation vocabulary: a walk that could not complete
   is `readable: false` with a named reason and **null** counts — never a zero, which reads as
   *nothing remains*, and never a landing verdict, because a wrong "this will land" is the
   answer that costs the operator the date.
4. A direction with **no** `target_date` gets a named answer, not an arithmetic one — there is
   no denominator, and inventing one would rank it against dated directions.
5. Keep it **evidence**: the output ranks and gates nothing. Tickets 2, 3 and 5 read it; this
   one decides nothing on its own.
6. Pin the shape and the degradation cases in `scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Per direction: what remains, how long is left, and whether the arithmetic clears it.
- A degraded read is named by its reason with null counts, never zeros.
- A dateless direction is named as such, never ranked against dated ones.
- No new walker, no new relation, no new field on any artifact.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — shape and degradation rows.
- The script run against this repository's own board and read against `/standup`.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **Unchecked acceptance items and queued tickets are not the same unit**, and the derivation
  must not pretend they are. Say what it counted rather than reducing to one number nobody can
  argue with.
- **No score, no weight, no tunable constant.** The repository has refused cross-direction
  arithmetic of that kind before (`survey-strategies.sh` orders by stated terms and nothing
  else); this answers a question per direction and leaves ordering to ticket 3.
- Attribution is transitive and lossy (`exhaustive: false`), so work no direction claims is
  outside this reading by construction. State that limit where the reading is read, or the
  first surprising answer will be read as a bug.

## Final Report

Development completed as planned. `strategy/scripts/landing-arithmetic.sh` answers, per direction,
what remains against how long is left, in four verdicts (`clears`, `does_not_clear`,
`no_target_date`, `unreadable`). It composes `standup/scripts/digest.sh` — the reading that
already assembles each direction's missions, their acceptance and queued counts, and its
`days_to_target` — and divides. 23 hermetic rows pin the shape, the degradation, the dateless
case and the structural claims; the script was also read against this repository's own board.

### Discovered Insights

- **Insight**: The obvious rate numerator was wrong, and only a measurement showed it.
  `digest.sh`'s `active_count` counts every attributed artifact that *changed* in the window —
  a mission file a changelog append rewrote, a story the report wrote — and read **502** against
  50 queued tickets here, so every direction cleared by construction and the reading said
  nothing. The numerator has to be the same unit as the remainder: tickets that reached `done`
  inside the window (337, against 351 archived repository-wide, which is the cross-check).
  **Context**: any future reading that divides a remainder by a rate has the same trap. State
  the unit of both sides before writing the arithmetic.
- **Insight**: The caps in `digest.sh` are *render* caps, and a consumer that computes over its
  output must raise them. `STANDUP_MAX_STRATEGIES`/`STANDUP_MAX_ITEMS` bound what a morning post
  shows; an arithmetic over a truncated mission set under-counts what remains and answers
  `clears` for a direction it had not finished reading — the one wrong answer this must never
  give. **Context**: the same applies to any later consumer of `digest.sh`.
- **Insight**: `digest.sh` costs ~110s on this repository, dominated by its honesty-line loop —
  one `git log` per corpus file. Anything composing it inherits that. It was taken deliberately
  here rather than duplicating the composition, but a third consumer would make the honesty
  line's cost worth attacking at its source.
