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

# Offer the executor work in a derived order

## Overview

PROPOSED. `plan-units.sh` surveys the queue and partitions it into PR-units, but nothing states
the order the units come back in — so which work an unattended tick picks up is whatever the
walk happened to produce. With 30 tickets queued against three directions dated the same day,
that is the difference between converging one direction and touching all three. `/propose`
already orders its own candidates by stated terms (stage first, then late-first, then nearest
date) and says so in the reader's own header so no consumer re-derives it. This gives the
executor's offer the same treatment: an explicit, derived, stated order.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the survey and partition; where the offer order is decided today by omission.
- `plugins/workaholic/skills/strategy/scripts/survey-strategies.sh` — the precedent: order stated in the reader's own header.
- `plugins/workaholic/skills/strategy/scripts/mission-strategy.sh` — answers which direction a mission serves, without a field.
- `plugins/workaholic/skills/drive/SKILL.md` — the Unified Run, where the order is read.

## Implementation Steps

1. Establish the current behaviour first: show what order `plan-units.sh` returns units in
   today and that no document states it. An undocumented order is not a bug until something
   depends on it — which is precisely what this ticket makes true, so it must be written down.
2. Order by stated terms and nothing else. Proposed, in order: a **mission unit before loose
   backlog** (a mission is a sequenced plan and its tickets are already ordered within it),
   then the **nearest `target_date`** of the direction the mission serves, then the mission's
   own ticket order. Each term is a fact already derivable; none is a score.
3. Resolve the direction through `mission-strategy.sh` — the existing reader — so this adds no
   relation and no field. A mission no direction claims sorts after the attributed ones by a
   stated rule, never by an invented date.
4. **State the order in the reader's own header**, as `survey-strategies.sh` does, so no
   consumer re-derives it and a later change moves one place.
5. Degrade honestly: an unreadable direction or date must not reorder silently — such a unit
   takes the stated fallback position and the reading names why.
6. `/drive` still asks which units to take; this changes the order they are offered in, never
   which are offered or how many. `/implement` takes them in the offered order.
7. Pin the order in `scripts/test-workflow-scripts.mjs` against a fixture board.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The offer order is deterministic and matches the stated terms.
- The order is documented in the reader's own header.
- Which units are offered, and the exclusion reasons, are unchanged.
- An unreadable term takes the stated fallback and is named.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — an order row over a fixture board with two
  directions, one loose ticket and one unattributed mission.
- `plan-units.sh` run against this repository, output read against the strategy dates.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **Ordering must not change eligibility.** `pace` in `survey-strategies.sh` is the precedent
  and the exact wording to hold to: it *changes order, never eligibility*. A unit that is
  offered today must still be offered, in a different position.
- The claim protocol means two runners can still take units in different orders; this reduces
  collision, it does not arbitrate. Do not present it as a fix for racing, which has its own
  measured mechanism.
- Sequencing missions strictly (one at a time) was **not** chosen here: that is ticket 2's
  limit, declared by the operator, and doing it twice in two places is how two brakes disagree.

## Final Report

Development completed as planned. `plan-units.sh` now returns `missions[]` in a derived order
stated in its own header: a mission unit before loose backlog, then the nearest `target_date` of
the direction the mission serves (through `mission-strategy.sh`), then the mission's own ticket
order. Each row carries `direction`, `direction_target_date`, `days_to_target` and
`order_reason`; the four groups run `direction_date` → `direction_undated` → `unattributed` →
`direction_unreadable`, with the walk order breaking every tie. Which units are offered and every
exclusion reason are unchanged.

### Discovered Insights

- **Insight**: `2>/dev/null` on an embedded jq program hid a real defect for a whole test cycle.
  `$bad | index(.slug)` indexes the *array* with a string — a jq runtime error (exit 5), not a
  compile error, so `moderate/scripts/lib/jq-guard.sh` would not have caught it either. The
  survey silently kept its walk order and the new fields came back `null`. **Context**:
  `rules/shell.md` classifies compile errors as our defect; this is the same class one exit code
  over, and the only thing that surfaced it was reading the output rather than the exit status.
- **Insight**: The fix for a failed derivation is to *say so on every row*, not to fall back
  quietly. An unannotated walk order is indistinguishable from a derived one that happened to
  agree, which is precisely the state this ticket exists to end — so the same jq program is run
  again with the reason forced, yielding the walk order with `direction_unreadable` on each row.
  Extracting the program into `order_missions()` is what makes the fallback the *same* ordering
  rather than a second copy.
- **Insight**: `mission-strategy.sh` costs ~21s here and now runs once per survey, on the
  executor's hot path. It is a local read, so `plan-units.sh` stays offline by construction —
  that property mattered more than the seconds, and it is why the resolver was called from the
  caller's side of the survey rather than being given a network fallback.
