---
created_at: 2026-08-22T22:41:39+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission:
merge_policy:
feedback: [20260822224122-one-proposal-per-tick-starves-the-slower-direction.md]
verification_handoff: 
claim: work-20260822-224335
---

# Propose against every eligible strategy in the tick

## Overview

`survey-strategies.sh` caps a tick at one proposal across all strategies
(`WORKAHOLIC_PROPOSE_MAX`, default 1), taking the eligible strategy with the nearest
`target_date` and reporting the rest as `over_cap`. The cap is removed: a tick proposes against
**every** eligible strategy — everything it can conclude at that moment.

**The cap does not reduce work; it fixes an order.** Total volume is already bounded by
`work_waiting` and `open_proposal`, which together give *one proposal per strategy in flight at
a time*. So the case the cap was written against — "a developer carrying eight directions must
not wake to eight issues at `:40`" — can only arise when all eight are idle, and then eight
directions each genuinely need their next move. What the cap actually does is put some
directions permanently behind others.

**And it does so backwards.** A strategy is skipped when its own work is in flight, so the
direction whose work takes *longer* gets proposed against *less often*. The direction that most
needs its next move is the one the cap starves.

**Measured** on a consuming repository: two active strategies with the **same** `target_date`.
One builds a platform and its build work sits queued for hours, so it is `work_waiting` on every
tick; the other is documentation, drains fast, and is therefore eligible on every tick. The
channel filled with one direction's output while the other never got a turn — and the developer's
ruling was that one proposal per tick is not enough, the tick should propose everything it can
conclude.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — `CAP` (~line 101), the
  `$ok[0:$cap]` / `$ok[$cap:]` split (~lines 192-194), and the header paragraph stating the
  one-per-tick rule (~lines 64-69). Read that paragraph before removing it; its reasoning is
  answered here, not ignored.
- `plugins/workaholic/skills/propose/SKILL.md` — the gate list and the `over_cap` bullet.
- `plugins/workaholic/commands/propose.md` — names the gates.
- `CLAUDE.md` — the `/propose` row states `over_cap` and its default.
- `scripts/test-workflow-scripts.mjs` — the propose gate tests.

## Implementation Steps

1. **Reproduce before changing anything.** Build a fixture with two eligible strategies and
   confirm from `survey-strategies.sh` that exactly one is taken and the other is reported
   `over_cap`. Establish the ordering rule (`days_to_target` ascending) and what happens on a tie.
2. **Localize.** Confirm `CAP` is read in one place and applied in one place, and that no other
   consumer depends on `cap` being present in the output.
3. Remove the cap: every eligible strategy is taken. Keep `work_waiting` and `open_proposal`
   exactly as they are — they are what bounds the volume, and removing the cap must not touch
   them.
4. Decide what happens to the `over_cap` reason and the `cap` output field, and say why. A reason
   nothing can emit is dead vocabulary; if the field is kept for a caller, keep it honest.
5. Keep the ordering: eligible strategies are still processed nearest `target_date` first, so a
   tick that dies partway has advanced the most urgent direction rather than an arbitrary one.
6. Record in the script header and the SKILL that the original reasoning was **answered rather
   than dropped**: the volume bound was never the cap's to provide, and the cap's real effect was
   to starve whichever direction was slowest.
7. Update `CLAUDE.md` and `commands/propose.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick with N eligible strategies proposes against all N.
- A strategy gated by `work_waiting` or `open_proposal` is still gated, unchanged.
- Eligible strategies are still ordered nearest `target_date` first.
- No refusal reason is reported that nothing can produce, and every surface naming the gates
  agrees with the code.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-propose`
- A fixture with three strategies — two eligible, one `work_waiting` — asserting two proposals
  and one named refusal.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the propose drill are clean.

## Considerations

- `WORKAHOLIC_PROPOSE_MAX` may still be wanted as an explicit opt-in bound for an operator who
  really does want fewer. If it is kept, its default must be unbounded, and the SKILL must say
  that the default is unbounded on purpose — a default of 1 is what produced the starvation.
- This raises the ceiling on issues opened per tick. That is the intent: the loop's output should
  be what it can conclude, and the brake belongs on *work in flight per direction*, which already
  exists.
