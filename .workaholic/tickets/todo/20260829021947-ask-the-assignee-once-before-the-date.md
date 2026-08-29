---
created_at: 2026-08-29T02:19:47+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: warn-a-direction-before-its-date-silences-the-loop
merge_policy:
verification_handoff: 
---

# Ask the assignee once before the date

## Overview

PROPOSED. `/moderate`'s `direction-health` step gains
**`direction-expiring:<slug>`**, addressed to that direction's **assignee**,
naming the date, the days left, and the leaving — what the direction never
reached and what no direction claims.

This is the reading's whole point: `past_target_date` silences origination, and
until now the only signal was `direction-overdue`, asked once, after the fact.
The precedent is `direction-last:<slug>`, which names the last live direction to
its owner *while they can still act* rather than announcing silence afterwards to
nobody. Expiry is that same event by a different cause.

Every existing gate applies **unchanged**: the asked-once gate, the per-tick cap,
the quiet hours, the working-day hold and the ruling suppression. And the step
stays **silent for a direction that already drew a non-`live` question this
tick**, so one direction never draws two — the doubling `handoff-units` and
`stalled-units` were split to avoid.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — the finding must reach the one person who can act on it

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the
  subjects block, the addressee resolution, the leaving clauses and the
  already-drew-a-question guard.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — read only; the
  gate, the cap and the holds must not move.
- `plugins/workaholic/skills/moderate/scripts/ruling-suppression.sh` — read
  only; confirm whether an expiring subject is suppressible (it is about the
  date, which no ruling answers — so it is **not**, exactly as `overdue` and
  `dormant` are not).
- `plugins/workaholic/skills/notify/reference/notifications.md` — the one-sentence
  body bound the heading/body split answers to.

## Implementation Steps

1. Read `step-direction-health.sh` end to end: the subject construction, the
   `$leaving_clause` composition, the `direction-last` guard that keeps one
   direction from drawing two questions, and the summary line.
2. Add the `expiring` subject beside `overdue` and `dormant`, keyed
   `direction-expiring:<slug>`, addressed to the direction's assignee.
3. Compose its heading and body on the existing split: the **named detail**
   (date, days left, the leaving's named residue) rides the **heading**, and only
   the **size** rides the body — `workaholic:notify` bounds the body to one
   sentence of 25 words, reserved for the operator's act. The act here is
   *re-date it, close it with a successor, or let it end*.
4. Read the leaving from the row's `leaving` field (ticket 4) — **never** call
   `closing-residue.sh`, `unattributed-work.sh` or `attributed-work.sh` from this
   step. A **degraded** leaving renders nothing, suppresses nothing, and is
   counted in the log-facing summary.
5. Extend the one-direction-one-question guard so an `expiring` reading is
   silent when that slug already drew a non-`live` question this tick, and so
   `direction-last` stays silent for a slug that drew this one.
6. Add `expiring` to the log-facing summary counts. Confirm the step still
   **asks and nothing else**: nothing re-dated, closed, amended, proposed or
   gated.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An expiring direction draws exactly one `direction-expiring:<slug>` question,
  addressed to its assignee, over two consecutive ticks.
- The question names the date, the days left and the leaving; the body is one
  sentence naming the operator's act.
- A direction that already drew `arrived`, `overdue` or `dormant` this tick
  draws no expiring question, and vice versa.
- A degraded leaving produces no leaving detail and suppresses no question.
- `ask-question.sh` is unmodified; the cap, the holds and `already_asked` are
  byte-identical.
- The step writes nothing anywhere but its own tick-log line, and reaches
  `plan-units.sh` at no point.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the key, the asked-once gate over
  two ticks, the mutual-exclusion cases, and a pin that the step reaches none of
  the three leaving readers directly.

**Gate** — what must pass before approval:

- The addressee is resolved the way the neighbouring subjects resolve theirs; an
  unmapped assignee leaves the question addressed to nobody rather than stamping
  an address nobody verified.

## Considerations

- The asked-once gate keys on the step id, so **changing the body never re-asks**
  a question. That is a feature and a constraint: the wording must be right the
  first time, because a later improvement reaches nobody who was already asked.
- `unreadable` is counted and never asked about, exactly as it is today. Do not
  spend a person's attention on our own degradation.
