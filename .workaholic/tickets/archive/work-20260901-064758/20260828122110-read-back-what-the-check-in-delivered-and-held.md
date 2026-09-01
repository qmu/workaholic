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

# Read back what the check-in delivered and held

## Overview

The step reports `ok — up to 5 questions may be asked this tick; 14 held from an earlier
tick`: a statement about **capacity**, not about **delivery**. Make it report what it
actually delivered, what it held, and **why** each was held — and distinguish a cap
genuinely spent today from a mechanism that has stopped.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — the running system says what it did

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — the step's
  `summary` and its run-report line
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the per-question refusal
  each hold is read from (`quiet_hours` / `off_day` / `tick_cap` / `day_cap` / `answered` /
  `already_asked`)

## Implementation Steps

1. Count, per tick: candidates offered, questions **asked**, questions **held**, and the
   hold count broken out **by the refusal reason the gate already returns** — no new
   vocabulary, no second derivation.
2. Name the two states the current line conflates: a cap **spent today** (questions were
   asked, and the ceiling was reached) versus a count that **could not be bounded** or a
   gate that delivered nothing at all. They read alike today and call for different acts.
3. Report a **degraded read as degraded, by its own reason** — an unreadable log is never
   rendered as a delivery, and never as a quiet hour.
4. Put the reading in the step's log-facing `summary`, where the tick's audit trail lives.
   The channel-facing half is ticket 5's `event`; keep the two separate, as every other
   step does.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The step's summary names asked, held, and the reason per hold.
- A cap spent today and a mechanism that delivered nothing render as different sentences.
- An unreadable log is named by its reason, never as zero questions.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — cases for the three readings over fixtures.

**Gate** — what must pass before approval:

- No question's gating changes: this ticket reads back, it does not decide.

## Considerations

- Keep the summary **stable under an unchanged world**. The root's change-detection is a
  diff of this string against the previous tick's, so embedding a timestamp or a raw count
  that moves every hour would make the step read as changed forever — the defect already
  normalized out for `inbound-sweep` and `doc-drift`.
- Hold counts are per tick, not cumulative; a running total would be the status line
  addressed to nobody this repository has twice retired.

## Final Report

**The work is already on the base**, landed while proposal #688 sat stranded. Verified:

- `step-human-checkin.sh` reports `delivered`, `held_count`, `candidates` and a `delivery`
  reason word on every exit path, replacing the capacity statement this ticket objected to.
- The reason words make the distinction the ticket asked for: **`cap_spent`** (the day's
  budget was spent — the mechanism worked) is split from **`cap_unbounded`** (the day count
  could not be bounded — our own degradation), and the header states that the second must
  never render as the first. `all_held`, `all_asked_before` and `no_candidates` complete the set.
- An unreadable log is `status: degraded` with the reader's own reason and **no `delivered`
  claim**; an absent log area is a readable answer, not a degradation.
- What `delivered` honestly is, is recorded too: the agent asks after `run.sh` returns, so on
  the step's own pass it is zero by construction and the words are ones the step can observe.

Nothing was re-implemented.
