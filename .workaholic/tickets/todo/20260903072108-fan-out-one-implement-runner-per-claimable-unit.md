---
created_at: 2026-09-03T07:21:08+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: decide-each-tick-s-allocation-from-what-the-tick-just-read
merge_policy:
verification_handoff: 
---

# Fan out one implement runner per claimable unit

## Overview

One agent per name caps `implement` at one whatever the queue holds. Eight active missions with
no claim on them, 54 tickets, and a rule that permits exactly one runner — adding capacity is not
merely un-attempted, the concurrency rule forbids it. The safety this rests on is already in
place: the claim protocol refuses a unit another run holds, and since 2026-09-02 `claim.sh` wins
one ref per claimed artifact before it creates anything, so two runners that survey together
cannot both take one unit.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — §2's concurrency rule and spawn table
- `plugins/workaholic/skills/loops/SKILL.md` — states one agent per name; this is what changes
- `plugins/workaholic/skills/drive/reference/claims.md` — the claim protocol and the arbiter
  (`claim-arbitrate.sh`), the reason a fan-out is safe
- `plugins/workaholic/skills/drive/scripts/claim-arbitrate.sh` — the create-only lease per
  claimed artifact; the loser refuses `claim_race_lost` holding nothing

## Implementation Steps

1. Narrow the concurrency rule from *one agent per name* to *one agent per name for `propose`
   and `moderate`, and up to the declared bound for `implement`* — stated in the command body
   and in `workaholic:loops` together.
2. Spawn `min(bound, claimable units)` `implement` runners, each under its own name
   (`implement-1`, `implement-2`, …), each in the background, each given `commands/implement.md`
   as its ceiling.
3. Do **not** hand a runner a unit. Each runs its own survey and claims what it can; the arbiter
   settles a race. Assigning units at the tick would put a second allocator beside
   `plan-units.sh`'s order, and a tick that names a unit is naming an identifier it cannot see
   the state of.
4. Count only `running` runners against the bound, so a fan-out does not compound across ticks.
5. State the cost: a losing claim race spends an agent run that produces nothing. That is the
   price of not assigning units, and it is bounded by the declared number.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Up to the declared bound of `implement` runners are spawned, never more.
- No runner is handed a unit; each surveys and claims for itself.
- Only `running` runners count against the bound.
- `propose` and `moderate` remain one per name.

**Verification method** — the commands/tests/probes that prove them:

- Set the bound to 3 with 3+ claimable units: three runners spawn and take different units.
- Set it to 3 with one claimable unit: one runner spawns.
- `sh scripts/e2e/loop-drill.sh verify-all` reports no new failure.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- No unit is assigned by the tick, and the claim protocol is untouched.

## Considerations

This meets the mission `stop-a-finished-subagent-and-take-the-loop-s-clock-off-it`, which bounds
an `/implement` run to one PR-unit. The two are complementary and neither subsumes the other: one
unit per run is what makes several runners coherent rather than several long-lived contexts. If
that mission has not landed, a fan-out multiplies the residency it removes — note the ordering in
the pull request.
