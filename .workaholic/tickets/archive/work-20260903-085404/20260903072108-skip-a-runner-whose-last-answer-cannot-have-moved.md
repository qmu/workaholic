---
created_at: 2026-09-03T07:21:08+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: decide-each-tick-s-allocation-from-what-the-tick-just-read
merge_policy:
verification_handoff: 
---

# Skip a runner whose last answer cannot have moved

## Overview

The strategy half produced zero proposals on every run of a two-hour session, each time
re-deriving a gate whose inputs could not have moved: `work_waiting` clears only when `implement`
drains the queue, and the tick had no way to accelerate that. Spending a full agent run to
re-derive it is the capacity the fan-out needed.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §2's cadence gate for the strategy
  half
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — owns the gate ladder; this
  ticket must not re-derive any of it
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — where a previous run's own reported
  answer is read from

## Implementation Steps

1. Read the **previous strategy run's own reported refusal** from the tick log — the gate's
   last answer, not a recomputation of it. When every direction was refused `work_waiting`, the
   strategy half is deferred.
2. Lift the deferral on the one event that can clear that refusal: an `implement` run landed a
   unit since. The tick learns this from its own task notifications, not from a queue reading.
3. Cap the deferral: after a stated number of skipped cadences the strategy half runs anyway.
   A brake with no ceiling is how the one routine that originates work stops silently, which
   this repository has measured twice.
4. Defer **only** on `work_waiting`. Every other refusal — `arrived`, `observing`,
   `past_target_date`, `not_active` — is left walking on its cadence, because those clear
   through a person's act that leaves no trace the tick reads.
5. An unreadable log defers nothing and is reported: a gate that cannot be read is not a gate.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The deferral reads a previous run's reported answer and re-derives no gate.
- It fires only on `work_waiting`, never on another refusal.
- It has a stated ceiling after which the strategy half runs regardless.
- An unreadable log defers nothing and says so.

**Verification method** — the commands/tests/probes that prove them:

- With every direction `work_waiting` and no unit landed, the strategy half is deferred and the
  tick reports it.
- After the ceiling, it runs regardless.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- `survey-strategies.sh` is byte-identical and no gate is duplicated.

## Considerations

**The tension is real and is named rather than resolved silently.** The command body rejects
state-dependence for `propose` by name — *has the queue moved is a second derivation of the gate
`/propose` already owns* — and the ask engages that argument directly, granting it for the
strategy half. Reading the gate's own **last reported answer** is not the same act as
recomputing it, but it is adjacent, and the ceiling in step 3 is what bounds the damage if the
distinction turns out to be thinner than it looks. If the driving session judges the distinction
does not hold, the honest outcome is to implement the ceiling alone — the strategy half on a
longer cadence — and report that, rather than adding a detector the objection forbids.

## Final Report

Development completed as planned. The deferral reads the **previous strategy run's own reported
refusal** from the tick log through `log-read.sh` — the gate's last answer, never a recomputation
of it — and `survey-strategies.sh` is byte-identical.

Four bounds, each a refusal in its own right: it is **lifted** the moment an `implement` run lands
a unit, which the tick learns from its own task notifications and from no queue reading; it is
**capped** at `WORKAHOLIC_PROPOSE_DEFER_MAX` skipped cadences (default 3), after which the
strategy half runs regardless; it fires **only** on `work_waiting`, since `arrived`, `observing`,
`past_target_date` and `not_active` each clear through a person's act that leaves no trace the
tick reads; and an **unreadable log defers nothing** and is reported `cadence_unreadable`.

### Discovered Insights

- **Insight**: Reading a previous run's *reported answer* is categorically different from
  re-deriving its gate, and that distinction is what keeps this from being the change-detector the
  command body refuses by name. The ladder stays `/propose`'s; what the tick reads is a fact about
  what already happened, which is the same thing `blocked-tick` and the `/moderate` change diff
  read the log for.
  **Context**: Any future brake on a cadence should reach for the same seam rather than a second
  derivation of the gate it is braking.
- **Insight**: The cap is the load-bearing half. A brake on the one routine that *originates* work
  is the shape that has twice stopped this loop silently, and a ceiling after which it runs anyway
  is what makes the brake safe to add at all.
  **Context**: Stated here because a later reader tuning the default will be tuning the safety
  margin, not a performance knob.

