---
created_at: 2026-08-28T12:21:10+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# Drain a multi-day question backlog oldest-held first

## Overview

Unbinding the count without an order lands the arrears as one wall — fifteen findings
were held at the time of the ask (7 `undrivable-unit`, 3 `retire-blocked`, 1
`handoff-unit`, 1 `direction-dormant`/`direction-last`, 1 `stalled-unit`, 1 `stuck`).
Order the tick's candidates **oldest-held first**, still bounded by the unchanged
`max_per_tick`, so the arrears arrive over several ticks in the order they went stale.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testability.md` — machine-checkable gaps caught early

## Key Files

- `plugins/workaholic/skills/moderate/scripts/run.sh` — where the steps' candidates are
  assembled and handed to the check-in
- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — the asking step
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the log the order is read from

## Implementation Steps

1. Decide the ordering key: **the day a candidate was first held**, read from the tick log
   the tick already keeps. A candidate never held before is newest by definition.
2. Read it through `log-read.sh` — no second ledger, no new log field, no stored cursor.
   Where a candidate has no held record, order it after everything that does.
3. Sort the check-in's candidate list on that key before the per-tick cap is applied, so
   the cap takes the **oldest** held findings rather than whichever step ran first.
4. Leave `max_per_tick` at its value and leave every gate's semantics alone: this changes
   **order**, never eligibility — the same discipline `/propose`'s `pace` reading holds.
5. Prove the order over a fixture spanning several days, and prove the cap still bounds it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Given more candidates than `max_per_tick`, the tick asks the oldest-held ones first.
- `max_per_tick` still bounds the count; a tick never asks more than it did before.
- No candidate is dropped — an unasked one is held and offered on the next tick.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a case over a multi-day fixture asserting
  both the order and the cap.

**Gate** — what must pass before approval:

- No second ledger, no new field on any artifact, no cursor stored anywhere.

## Considerations

- The ordering must be **total and deterministic**: two candidates first held on the same
  day need a stable tiebreak (the step id is already unique per question) or the drain
  order changes between ticks for no reason.
- Ordering is not prioritisation by severity. Urgency here means *how long it has waited*,
  which is mechanical; ranking the four verdicts against each other would be a judgement
  this step has no basis to make.

## Final Report

**The work is already on the base**, landed while proposal #688 sat stranded. Verified:

- `step-human-checkin.sh` orders `held` by the day each key was **first** held, tie-broken on
  the tick id and then the key (`LC_ALL=C sort` over a composed line), so the order is total
  and a re-entered tick produces a byte-identical sequence. Its header records what the order
  replaced — `sort -u`, alphabetical over a set whose only meaningful order is age.
- The step **orders; it neither caps nor asks**: `max_per_tick` stays with `ask-question.sh`
  and `held_count` counts the whole set rather than a prefix. The handoff to the agent carries
  `"order": "the held list is ordered oldest-held first; take it in that order"`.
- Age rather than urgency is deliberate and recorded: a severity ranking across the step
  vocabularies is a judgement no script can make.

Nothing was re-implemented.
