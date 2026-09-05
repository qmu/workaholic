---
created_at: 2026-09-03T08:20:14+09:00
status: done
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

## Final Report

Development completed as planned.

§3 of the command body now carries one machine line **beside** the per-loop and allocation lines and
never in place of them, and `workaholic:loops` documents the line and its silence rule in the same
change. The line's whole contract is written as four refusals:

- **It says it only when it has something to say.** A tick the machine held names the refusal, the
  load and the core count (`load_saturated: 7.99/4`); an unheld, readable machine adds **no** line,
  because an unchanged answer restated every tick is what `📦 Release Preparation` was retired for.
- **A degraded reading is named by its reason and never rendered as headroom** — `the machine could
  not be read this tick (no_loadavg); the fan-out was not bounded by it`.
- **It carries no identifier and no mention token**: a fact about the machine, addressed to nobody,
  and naming a unit would put a task on a line addressed to nobody.
- **It reaches Slack through nothing.** This is the tick's own run report, and the loop posts no
  status line about its own capacity, for the reason the two retired status roots record. Gate
  checked: the change adds no Slack post, reaction or thread lookup anywhere — it touches
  `commands/infinite-development.md`, `skills/loops/SKILL.md` and `CLAUDE.md`, and no notify shape,
  transport or lookup moved.

It also says **what the machine was and whether it held the fan-out**, and deliberately not what the
tick would otherwise have spawned: a counterfactual count is a second derivation of the allocation
the tick already owns.

### Discovered Insights

- **Insight**: the silence rule here is the same one `/moderate`'s `📋` clause already holds for the
  repository's `wip_limit` — say it when it moved, stay silent when it did not, and never let a
  quieter loop be indistinguishable from a stopped one.
  **Context**: the rule is now stated in two places for two different surfaces (the hourly root and
  the tick's run report). A third surface that wants a status line should read either of them rather
  than re-deriving the trade-off, which is what produced the two retired status roots.
- **Insight**: the three tickets of this mission are one documentation change across three files, so
  the first archive commit carries the whole edit and the later two carry only their Final Reports.
  **Context**: per-ticket commit granularity is a property of when the edits were made, not of the
  archive seam. The branch story and `archive/<branch>/` hold the per-ticket record; a reader looking
  for the code behind ticket 2 or 3 should read the branch, not the individual archive commit.
