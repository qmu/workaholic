---
created_at: 2026-08-26T02:23:47+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826022347-judge-a-whole-mission-not-one-change.md
mission: turn-the-loop-at-mission-granularity
merge_policy:
verification_handoff: 
---

# Bound the brake to one mission per strategy

## Overview

`/propose`'s brake is `work_waiting` + `open_proposal` — one gate in two halves that hand off
with no window, giving *one proposal per strategy in flight at a time* with no cursor and no
stored state. Both halves count work at the **change** grain: `attributed-work.sh`'s
`waiting_count` over queued tickets, and `list-open-proposals.sh` over open issues. When a
proposal becomes a whole mission, the same arithmetic must mean *one mission in flight per
strategy* — otherwise a mission's own seven queued tickets read as seven units of waiting
work, or, worse, the halves stop covering each other and a second mission is proposed against
a strategy whose first is still being driven.

## Policies

- `workaholic:implementation` / `policies/fail-fast.md` — a gate that cannot be read is not a gate
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — where the gates are
  computed and reported by name
- `plugins/workaholic/skills/propose/scripts/list-open-proposals.sh` — the remote half
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — `waiting_count`,
  `waiting_kind`, `waiting_describing`, `waiting_advancing`
- `plugins/workaholic/skills/propose/SKILL.md` — *The bar this drops, and the brake that
  replaces it*
- `scripts/e2e/loop-drill.sh` — `verify-propose`

## Implementation Steps

1. Re-express `work_waiting` at the mission grain: a strategy with an **active attributed
   mission that still has queued tickets** is gated. Derive it from the readers that already
   exist — `attributed-work.sh` for attribution, `queue-size.sh` for the queue — rather than
   adding a counter.
2. Keep `describing` versus `advancing` intact. The 2026-08-23 fix exists because describing
   work cites the same refs as building work and kept the gate closed against the build; a
   mission-grain count must not undo it. A mission whose queued tickets are all `describing`
   must still not gate an advancing proposal.
3. Re-express `open_proposal` to match: an open mission-shaped proposal for that strategy
   gates it, exactly as an open change-shaped one did. The two halves must still hand off
   with **no window** — verify the seam rather than assuming it survives the change.
4. Keep every refusal reported by name (`not_active`, `not_mine`, `past_target_date`,
   `no_feedback_refs`, `work_waiting`, `open_proposal`, `attribution_unreadable`,
   `inbox_unreadable`) and keep `pace` as evidence that changes order, never eligibility.
5. State the resulting rate plainly in the SKILL: one mission per strategy in flight,
   re-proposed when that mission finishes — the "turns at mission granularity" the ask asks
   for, with no cursor and no stored state.
6. Extend `verify-propose` to cover the gated and un-gated cases with no network.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A strategy with an active attributed mission holding queued tickets is refused
  `work_waiting`; the same strategy with that mission finished is eligible
- An open mission-shaped proposal refuses `open_proposal`, and the two halves leave no window
- `describing` work still does not gate an advancing proposal
- Every refusal is reported by name; `pace` still changes order, never eligibility

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-propose`
- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The drill proves both the gated and the un-gated case with no network

## Considerations

- **Do not reintroduce a per-day cap.** `over_cap` was retired on 2026-08-22 with its reasoning
  recorded: it reduced no total (the two-half gate already bounds volume) and fixed the order
  backwards, penalising the strategy whose work takes longer. The bound stays derived.
- The failure to watch for is a **widened window**: if the mission grain makes `work_waiting`
  false before `open_proposal` becomes true, a tick proposes a second mission against a
  strategy that already has one. That seam is the ticket's real risk and is why it is verified
  rather than reasoned about.
