---
created_at: 2026-09-03T13:39:32+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-verification-handoff-a-probe-re-run-at-claim-time
merge_policy:
verification_handoff: 
---

# Drop a handoff whose probe comes back clean

## Overview

A handoff that probes clean is not a handoff. This is the ticket that changes behaviour:
the route asks the runner at claim time, and a `clean` answer means the run performs the
verification and the unit takes its ordinary route instead of parking.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` — the claim act, where the probe is run
- `plugins/workaholic/skills/drive/reference/routing.md` — the route that reads the verification axis before merge policy
- `plugins/workaholic/skills/drive/SKILL.md` — the axis is stated here
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the survey's `awaiting_verification` exclusion
- `plugins/workaholic/rules/workaholic.md` — the fleet-facing statement of the axis

## Implementation Steps

1. Call `run-verification-probe.sh` from the claim act, once, for the unit being claimed —
   re-deriving the answer at the moment of the act, which is the rule a bounded act must satisfy
   to read a judgement (`drive/reference/claims.md`).
2. On **`clean`**: the unit takes its ordinary route by `merge_policy`. Record the probe, its
   exit status and its output in the run report, so a dropped handoff is visible as a
   *measurement* rather than as an ignored declaration.
3. On **`blocked`**, **`unmeasured`**, **`unprobeable`** and **`unreadable`**: the `handoff`
   route is exactly what it is today. A reading that could not be made never drops a handoff —
   the safe side of this change is the existing behaviour.
4. State the precedence in `routing.md` and `SKILL.md`: the declaration still routes, and the
   probe is what can **lift** it. Nothing here lets a run *declare* a handoff for its own unit;
   that bound does not move.
5. Leave `awaiting_verification` and the survey's exclusion alone for a unit that stays handed
   off; a unit whose probe came back clean is claimed and drives, so it never reaches the
   exclusion.
6. Update `rules/workaholic.md` and `CLAUDE.md` in this same change: the axis's fleet-facing
   sentence is now *declared and re-probed at claim time*, not *declared at creation*.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit whose declared probe exits 0 is claimed and driven by its `merge_policy`, and the run report names the probe and its status.
- A unit whose probe exits non-zero, or which declares none, takes the `handoff` route exactly as today.
- An `unreadable` probe reading never drops a handoff.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — rows driving a unit with a passing probe, a failing one, and none.
- `sh scripts/e2e/loop-drill.sh verify-all` — the handoff drill, extended with a breaker row written against this behaviour.

**Gate** — what must pass before approval:

- Every existing declaration with no probe behaves byte-identically; the change reaches only units that declare one.

## Considerations

- A wrong `clean` merges work whose real-world verification never happened. That is why the
  probe's exit status is the only reading and why the timeout answers `blocked`: the failure mode
  is deliberately biased toward parking.
