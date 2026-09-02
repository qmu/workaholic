---
created_at: 2026-09-03T08:20:14+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: decide-each-tick-s-allocation-from-what-the-tick-just-read
merge_policy:
verification_handoff: 
---

# Report the machine reading beside the allocation

## Overview

A bound that fires silently is the failure this mission exists to end. The tick's §3 report says
per loop `spawned` / `still_running` / `not_due`; a tick held back by the machine would read as a
tick with nothing to do, which is byte-identical to a healthy idle one. **A quieter loop must not
be indistinguishable from a stopped one** — the rule `/moderate`'s `📋` clause already holds for
the repository's `wip_limit`, applied here to the machine's.

## Policies

- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §3, the report shape, and §2 where the
  reading is taken
- `plugins/workaholic/skills/loops/SKILL.md` — where the report's own contract is documented

## Implementation Steps

1. Add one line to §3's report, beside the per-loop lines and never in place of them: the cores,
   the one-minute load, and whether the machine held the fan-out.
2. **Say it only when it has something to say.** A machine under its ratio with no bound fired
   adds no line — an unchanged answer restated every tick is what `📦 Release Preparation` was
   retired for. A tick the machine held names the refusal, the reading and the core count.
3. **A degraded reading is named as degraded**, by its reason, and never rendered as headroom:
   `the machine could not be read this tick (no_loadavg); the fan-out was not bounded by it`.
4. It carries **no identifier and no mention token** — it is a fact about the machine, addressed
   to nobody, and naming a unit would put a task on a line addressed to nobody.
5. **It reaches Slack through nothing.** This is the tick's own run report, which the operator
   reads in the session; the loop posts no status line about its own capacity, for the reason the
   two retired status roots record.
6. Document the line and its silence rule in `workaholic:loops` in this change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A held fan-out reports the refusal, the load and the core count.
- An unheld, readable machine adds no line.
- A degraded reading is named by its reason and never as available headroom.
- Nothing is posted to Slack by this ticket.

**Verification method** — the commands/tests/probes that prove them:

- Force the bound with a low ratio: the report names `load_saturated` with the numbers.
- Run with the bound undeclared: the report is byte-identical to today's.
- Make the reading fail: the report says the machine could not be read and that the fan-out was
  not bounded by it.

**Gate** — what must pass before approval:

- No Slack post, reaction or thread lookup is added anywhere by this change.
- No line is emitted on an ordinary, unheld tick.

## Considerations

The line says *what the machine was and whether it held the fan-out*, and deliberately not *what
the tick would have spawned* — a counterfactual count is a second derivation of the allocation
the tick already owns, and this repository keeps one rule in one place.
