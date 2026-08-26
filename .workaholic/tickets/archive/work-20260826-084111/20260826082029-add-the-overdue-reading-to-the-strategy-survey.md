---
created_at: 2026-08-26T08:20:29+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Add the overdue reading to the strategy survey

## Overview

A direction past its `target_date` is refused `past_target_date` and stops there.
`pace` cannot carry it: `late` requires `(.landed | length) == 0`, so a direction that
sailed past its date **while producing work** reads `on_course`, is refused for a
correct reason, and produces no proposal and no question — forever. Add `overdue` as a
third named value beside `pace`, derived from `days_to_target < 0`, present on every
surveyed row (eligible and refused alike), so a later reader can see the state the
refusal already knew about.

It changes **no gate and no eligibility**: `past_target_date` refuses exactly as it does
today, and `overdue` never collapses into `late`, `on_course` or `unknown`.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the one place
  `days_to_target` and `pace` are derived; the new value is emitted in the same `jq`
  pipeline, on every row, before the `refusal` computation that must stay untouched.
- `plugins/workaholic/skills/propose/SKILL.md` — the reading and its refusals are stated
  where `pace` is stated, so the two are read together.
- `CLAUDE.md` — the `/propose` row names the survey's readings.

## Implementation Steps

1. Read `survey-strategies.sh`'s header and the `pace` block in full: the reading is
   defended there, and `overdue` must be argued in the same terms (a derivation with no
   threshold, from two terms already justified).
2. Emit `overdue` as its own field — a boolean or a third value — from `days_to_target <
   0`, on the row object, **before** `refusal` is computed, so the refusal expression is
   byte-identical to what it is today.
3. Carry it onto `refused[]` rows as well as `eligible[]` ones: the whole point is the
   refused case, and a reader that sees only `eligible` would never see it.
4. Leave the sort untouched. `late`-first then nearest date is a decided order; adding a
   third term to it is a separate judgment nobody has made.
5. State the reading in `propose/SKILL.md` beside `pace` and in `CLAUDE.md`, in the same
   commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `overdue` appears on every surveyed row, eligible and refused, and is `true` exactly
  when `days_to_target < 0`
- `past_target_date` still refuses the same strategies it refuses today, and `pace` is
  byte-identical for every row
- A row with no resolvable `target_date` reads `unknown`-safe: `overdue` is never `true`
  on a `null` `days_to_target`

**Verification method** — the commands/tests/probes that prove them:

- `sh plugins/workaholic/skills/propose/scripts/survey-strategies.sh | jq '.eligible +
  .refused | map({slug, days_to_target, pace, overdue})'` on this repository
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The survey's output is a superset of today's: no existing key changed name, type or
  value
- The documentation this change makes wrong is updated in the same commit

## Considerations

- The obvious shortcut is to fold `overdue` into `pace` as a fourth value. It is
  refused by the ask: `pace` answers *will this arrive*, `overdue` answers *has the date
  passed*, and one field answering two questions is how the two drift.
- `days_to_target` is computed against a UTC `$today`; a direction expiring today reads
  `0`, not `overdue`. That is the correct boundary and should be stated, not tuned.

## Final Report

Development completed as planned.

`survey-strategies.sh` emits `overdue` as its own boolean on every surveyed row — eligible
and refused alike — derived from `days_to_target < 0` and computed **before** `refusal`, so
the refusal expression, `pace`, the sort and `selected` are byte-identical to before. The
reading is stated in `propose/SKILL.md` (a section of its own beside *Pace*) and in
`CLAUDE.md`'s `/propose` row, in the same change.

### Discovered Insights

- **Insight**: `refused[]` carries two row shapes, not one — the real refusals get
  `{slug, reason, pace, overdue, title, assignees, days_to_target}`, while the `over_cap`
  spill rows appended after them carry only `{slug, reason}`.
  **Context**: `pace` set that precedent when it landed, and `overdue` follows it rather
  than widening the spill. The spill is unreachable by default anyway (`WORKAHOLIC_PROPOSE_MAX`
  defaults to unbounded), so a consumer that reads `overdue` off a `refused` row must tolerate
  its absence rather than assume every refused row is fully populated.
- **Insight**: the `pace: late` and `overdue: true` readings overlap only by accident. A
  direction past its date with nothing landed reads both; the case this ticket exists for —
  past its date **while producing work** — reads `on_course` and `overdue: true`, which is
  precisely the pair `pace` alone could never express.
  **Context**: verified against a seeded tree rather than argued: `days_to_target: -237` with
  no landed work gave `pace: late, overdue: true`, and an undated strategy gave
  `pace: unknown, overdue: false`.
