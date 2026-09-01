---
created_at: 2026-08-31T11:25:34+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-check-in-queue-is-stuck-and-bound-the-hold
merge_policy:
verification_handoff: 
---

# Read how deep and how old the arrears are

## Overview

`step-human-checkin.sh` already derives, per held key, the day it was **first** held —
that derivation is what orders the arrears oldest-first for the drain. It is then thrown
away: only `held_count` survives onto the step's output, so the step knows how old its
backlog is and says only how large it is. Carry the reading it already made.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — the step; owns
  the first-held-day derivation used for ordering, and the JSON this adds two fields to.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the log's one parser, which
  already emits `day` per entry. Read, never modified.


## Implementation Steps

1. Locate the first-held-day derivation the ordering already performs; take its
   **minimum** rather than re-walking the log — no second walker, no cursor, no store.
2. Emit `held_oldest_day` (that day, `YYYY-MM-DD`) and `held_days` (whole days from it to
   the tick's own day) beside the existing `held_count`. The tick's day is the one
   `ask-question.sh` already derives from the tick id; read that, never a wall clock and
   never a second notion of a day.
3. A **degraded** log read reports **null** for both, never `0` — a zero here reads as
   *this just started*, the most reassuring thing the field can say, for a reading that
   was not made. `status: degraded` and its reason are unchanged.
4. A tick with **no** holds emits `held_count: 0` with both new fields null, and is
   otherwise byte-identical to today's output.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick whose held set spans several days reports `held_oldest_day` as the earliest of
  them and `held_days` as the whole-day distance to the tick's day.
- A degraded log read reports both as null with no `delivered` claim.
- A tick with no holds is byte-identical to the pre-change output apart from the two null
  fields.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-checkin-delivery`

**Gate** — what must pass before approval:

- No new store, no cursor, no second walk of the log, and `log-read.sh` unmodified.


## Considerations

- The day grain is coarse by design (the ordering already accepts it) and the log's
  **files** are keyed by UTC day while the tick's day is `WORKAHOLIC_QUIET_TZ`'s — near
  the boundary the age reads one day high rather than one day low, which understates
  nothing and is the direction already accepted for the day cap.


## Final Report

Development completed as planned.

`step-human-checkin.sh` now carries the first-held day the drain ordering already derived
instead of discarding it: the ordered key list emits `day:key` rather than the key alone,
and the minimum day over the keys **still** held becomes `held_oldest_day`. `held_days` is
the whole-day distance from that day to the tick's own day, and the tick's day is derived
from the tick id on exactly the axis `ask-question.sh` uses for its day bound. There is no
second walk of the log, no cursor, no store, and `log-read.sh` is unmodified.

A degraded read reports both as `null`; a tick with no holds reports `held_count: 0` with
both `null` and is otherwise byte-identical to the previous output.

### Discovered Insights

- **Insight**: the distance between two `YYYY-MM-DD` strings is computed by civil-day
  arithmetic in `awk`, never through `date`.
  **Context**: `date -d` is GNU-only and `date -v` is BSD-only, a refusal
  `condition-age.sh` already states by name — which is why that reader counts distinct tick
  ids rather than days. Here a genuine day distance was wanted, so the arithmetic is done
  in `awk` (portable, pure, no subprocess of a system tool whose flags differ by platform).

- **Insight**: the minimum is taken over the keys that survive the asked-drop, not over
  every key the log ever held.
  **Context**: an asked key leaves the arrears — the ask is the resolution of the hold —
  so letting it go on ageing them would make a drained queue read as an ancient one.
