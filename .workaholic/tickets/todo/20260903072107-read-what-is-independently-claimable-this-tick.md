---
created_at: 2026-09-03T07:21:07+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: decide-each-tick-s-allocation-from-what-the-tick-just-read
merge_policy:
verification_handoff: 
---

# Read what is independently claimable this tick

## Overview

Nothing in the tick reads how much work is queued or where it is, so the allocation cannot
depend on it. Before a fan-out can be decided, the tick needs one reading: how many PR-units are
claimable right now and independent of each other. That reading already exists — `plan-units.sh`
is the executor's own survey and it partitions the backlog into PR-units, reports `excluded[]`
with a reason per unit, and names what a claim already holds.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the survey; the one place units are
  partitioned and ordered, and the reading this composes rather than re-derives
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the claim oracle, so a unit another
  run holds is never counted claimable
- `plugins/workaholic/commands/infinite-development.md` — §2, where the allocation is decided

## Implementation Steps

1. Compose `plan-units.sh` — never a second walker, never a count of `todo/` files, which would
   ignore missions, claims, ownership and every exclusion reason the survey already derives.
2. Count the units the survey **offers**, which by construction excludes `claimed_*`,
   `owned_by_other` and `mission_member` — the claim protocol's refusal is what makes the count
   safe to act on.
3. Report the count and the survey's own `ok`-forbidding facts. A survey that is not `current`,
   is `shallow`, or reads `owner_unresolved` / `placeholder_identity` yields **no** fan-out
   reading and says so: a gate that cannot be read is not a gate, and an allocation decided on a
   blind survey is worse than the fixed one.
4. Cost: this is one local survey per tick. Measure it and state it in the pull request; if it
   is not cheap enough for a five-minute tick, that is a finding to report, not a thing to work
   around with a lighter count.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The claimable count composes `plan-units.sh` and no second walker exists.
- A degraded survey yields no reading and is named by its own word.
- The cost of the survey per tick is measured and stated.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/drive/scripts/plan-units.sh` and compare the offered set
  against the reading.
- `node scripts/test-workflow-scripts.mjs` passes.
- `time` the survey in this repository and record it.

**Gate** — what must pass before approval:

- No second derivation of the backlog exists anywhere in the tick.

## Considerations

The survey is the executor's and the tick has never reached it. That is a real widening of what
the tick reads, and the reason it is admissible is that the reading is used to decide **how many
runners to start** and for nothing else — it never picks a unit, never orders one, and never
claims. `plan-units.sh`'s order stays the executor's.
