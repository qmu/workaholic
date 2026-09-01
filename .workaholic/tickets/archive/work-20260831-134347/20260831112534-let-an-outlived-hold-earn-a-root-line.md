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

# Let an outlived hold earn a root line

## Overview

The step supplies an `event` only for `cap_spent` and `cap_unbounded`, on its own
reasoning that quiet hours and an off day are the **designed** hold and are already named
in the log. That reasoning is right for one tick and wrong across days: measured, 24
consecutive ticks reported `all_held` with 13 questions behind them and the root said
nothing. A hold that has outlived the window that explains it is no longer a delay.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — where the `event`
  is supplied, and where the boundary is composed.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — read only: the root
  renders whatever event a step supplies, and its diff rule is untouched.


## Implementation Steps

1. Compose the boundary from the gate's **own** three variables — the first hour inside
   `WORKAHOLIC_WORK_DAYS` at the end of `WORKAHOLIC_QUIET_HOURS`, in
   `WORKAHOLIC_QUIET_TZ` — exactly as the red-alert cool-down's expiry composes it.
   **Introduce no constant**: every term is already justified and already read here, so
   the reading means *this hold outlived the window that was supposed to explain it*.
2. On the `all_held` branch, supply an `event` when `held_oldest_day` (the previous
   ticket's reading) is earlier than that boundary's day, naming the **depth** and the
   **age** — never a dedup key and never a mention token, since the root is addressed to
   nobody and the questions are its mentioned replies.
3. Leave every other branch exactly as it is: a hold **inside** the window supplies no
   event, `cap_spent` and `cap_unbounded` are byte-identical, and a delivering tick and a
   genuinely quiet hour both still render no line.
4. A **null** `held_oldest_day` (a degraded read) supplies **no** event: a reading we
   could not make is never dressed as one we did.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An `all_held` tick whose oldest hold predates the boundary supplies an event naming
  depth and age; one inside the window supplies none.
- Two consecutive such ticks with the same reading render **one** line, because the
  summary is a function of the reading alone.
- `cap_spent`, `cap_unbounded`, `all_asked_before`, `no_candidates` and the degraded
  branch are byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-checkin-delivery`

**Gate** — what must pass before approval:

- No tunable constant introduced; the boundary is composed from the gate's own three
  variables and from nothing else.


## Considerations

- The alternative — an escalation after N ticks — was available and is not taken: N is a
  tunable constant this repository refuses by name, while the working-day boundary is a
  derivation whose terms were already justified.
- The step still **asks nothing extra and holds nothing differently**: this changes what
  the root says, never which questions are asked or when.


## Final Report

Development completed as planned.

`step-human-checkin.sh` composes the boundary from the gate's own three variables —
`WORKAHOLIC_WORK_DAYS`, the end of `WORKAHOLIC_QUIET_HOURS`, `WORKAHOLIC_QUIET_TZ` — as
`boundary_back`, the number of days back to the most recent working-window opening (0 when
today's opening has already happened). No constant is introduced. An `all_held` tick whose
`held_days` exceeds that distance supplies an event naming the depth and the age; one inside
the boundary supplies none, a null reading supplies none, and `cap_spent`, `cap_unbounded`,
`all_asked_before`, `no_candidates` and the degraded branch are byte-identical.

### Discovered Insights

- **Insight**: the event had to be supplied on the `off_day` and `quiet_hours` branches, not
  only on the `ok` one, because `all_held` is not reachable on the `ok` branch at all.
  **Context**: on `ok`, `quiet_hours` and `off_day` cannot be the gate's answer (the step has
  already exited), and `tick_cap` requires five asks on the tick — which makes `delivered`
  non-zero, and the `all_held` derivation only runs when `delivered` is zero. The measured
  24 consecutive `all_held` ticks were therefore all in the two skipped branches, which is
  exactly where a weekend's or a night's arrears sit.

- **Insight**: comparing against the boundary needs no second date and no inverse
  day-to-date conversion.
  **Context**: `held_days` is already the distance from the oldest hold to the tick's day, so
  `held_days > boundary_back` *is* "the oldest hold predates the boundary's day". Deriving
  how many days back the opening is (0..7, the length of the week) keeps the whole
  comparison in integers.
