---
created_at: 2026-09-06T18:55:01+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: see-a-frozen-runner-and-give-back-its-slot
merge_policy:
verification_handoff: 
---

# Stop counting a non-advancing runner toward the fan-out

## Overview

The tick's allocation is `min(WORKAHOLIC_IMPLEMENT_FANOUT, claimable units, what the machine can
carry, bound − running)`, and `running` is whatever `ListAgents` says. A runner frozen on a
permission dialog is `running` forever, so it consumes a slot forever: measured 2026-09-06, with
`WORKAHOLIC_IMPLEMENT_FANOUT=3` and one frozen runner the loop was a 2-runner loop for 38
minutes and said nothing about it in any tick report.

The slot coming back is what actually recovers the work. The frozen runner's own claim heartbeat
lapses, and `claim.sh resume` takes over **your own** claim whose heartbeat lapsed — same
identity — so a runner spawned into the freed slot can pick the unit up. Without the slot, no
runner is spawned to do so.

Depends on the reader from `read-whether-a-running-loop-subagent-is-still-advancing`; this
ticket only spends its answer.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the allocation is an operational decision; a degraded reading holds
  nothing and is named

## Key Files

- `plugins/workaholic/commands/infinite-development.md` §2 — the fan-out expression and the
  concurrency rule; §3 — the allocation line and the machine line beside it
- `plugins/workaholic/skills/loops/SKILL.md` — where the tick's bounds and their measurements
  are recorded
- `plugins/workaholic/skills/loops/scripts/read-runner-advance.sh` — the reader this consumes
- `plugins/workaholic/skills/loops/scripts/claimable-units.sh` — the sibling reading, and the
  model for how a degraded count is named rather than collapsed to zero
- `scripts/test-workflow-scripts.mjs`, `scripts/e2e/loop-drill.sh`,
  `docs/loop-drill-runbook.md` §9 — the pins and the drill register

## Implementation Steps

1. Subtract from `running`, in the fan-out expression only, every loop the reader answers
   `not_advancing` for. Change **nothing** about the concurrency rule's other half: a loop whose
   subagent is `running` and **advancing** is still not spawned again.
2. **Name it in §3's allocation line** whenever it fires — the runner's name and the reader's own
   word — the way `load_saturated: <load1>/<cores>` names the machine bound. A bound that fires
   silently is the failure this whole mission exists to end.
3. **`unreadable:<reason>` frees nothing**, and the reading is reported by its own reason and
   never as headroom. This is the repository's standing rule: a gate that cannot be read is not a
   gate.
4. **Stop no agent and kill no work on this reading.** The unconditional `TaskStop` stays exactly
   where it is — on `idle` — and this ticket adds no second liveness authority. The slot comes
   back; the frozen session is the operator's to end, or the next `idle` observation's.
5. Record no new store, no cursor and no field on any artifact: the reading is taken fresh each
   tick, as `claimable-units.sh` and `read-machine-load.sh` are.
6. Pin the allocation expression and the §3 wording in `test-workflow-scripts.mjs`, and extend
   the mission's drill so a frozen fixture demonstrably frees a slot.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `not_advancing` runner does not consume a fan-out slot.
- The tick report names the freed slot, the runner and the reader's word, and adds no line when
  nothing was freed.
- An `unreadable` reading frees nothing and is named by its own reason.
- No agent is stopped, no unit is killed, and the concurrency rule for an advancing runner is
  byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- The mission's drill, with a frozen fixture and an unreadable one.

**Gate** — what must pass before approval:

- The above pass, and no new store, cursor or artifact field was introduced.

## Considerations

- **Freeing the slot without the claim would be half a repair, and it is not.** The claim
  protocol already answers it: the frozen runner's heartbeat lapses, and `claim.sh resume` takes
  over one's own lapsed claim. This ticket must not add a second path to release a claim.
- **The risk is a false `not_advancing` on a slow unit**, which would spawn a second runner
  against a working one. The claim arbiter settles the race and the loser refuses
  `claim_race_lost` holding nothing — so the cost is bounded — but the reader's precision is the
  previous ticket's obligation, not something to compensate for here.
- **Adding a line every tick was refused elsewhere**, and the same refusal applies: an unheld,
  readable allocation adds no line, exactly as the machine line does not.
