---
created_at: 2026-08-27T11:25:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-operator-revise-a-live-direction-through-the-loop
merge_policy:
verification_handoff: 
---

# Name the revision act in the direction-health questions

## Overview

PROPOSED. `/moderate`'s `direction-health` step states the operator's own next act in
their vocabulary. Its `overdue` body reads *"Announce that it ended, or say it still
stands — the loop will not close or change it either way."* Both halves are honest today
and one becomes wrong once a revision path exists: re-dating is now an act the operator
can take through the loop, and the question that asks about an expired direction must
name it. This ticket moves the wording and nothing else.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the `subjects`
  jq block; `heading` and `body` per reading, and the header stating why the step supplies
  the wording.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step's contract.
- `scripts/e2e/loop-drill.sh` — `verify-direction-health`, which drills the readings and
  the question keys.

## Implementation Steps

1. Change the `overdue` body to name three acts, not two: re-date it, announce that it
   ended, or say it still stands. Keep it inside `workaholic:notify`'s 25-word bound and
   keep the three-part order the header mandates (reading, slug, the operator's act).
2. Change the `dormant` body the same way only if a revision is genuinely one of its
   answers — a direction nothing is answering is not obviously mis-dated, so prefer
   leaving it and say why in the header rather than widening it by reflex.
3. Keep the act named in the **operator's** vocabulary: *re-date it*, never *run
   `amend.sh`*. The announcement is the sanctioned route and the script is not theirs to
   run.
4. Keep the closing clause honest. "The loop will not close or change it either way" is
   still true — the loop carries the revision the operator announces and never decides
   one — so restate it rather than dropping it.
5. Move **nothing else**: the question keys (`direction-overdue:<slug>` /
   `direction-dormant:<slug>` / `direction-none`), the asked-once gate, the per-tick cap,
   the quiet hours and the working-day hold are untouched.
6. Update `verify-direction-health`'s expectations in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The `overdue` body names the revision act and stays within the word bound.
- Every question key, gate and hold is byte-identical to before.
- `verify-direction-health` passes with the new wording.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-direction-health`

**Gate** — what must pass before approval:

- The suite and the drill are green, and no key changed.

## Considerations

- Changing a question's body does **not** re-ask it: the asked-once ledger keys on the
  step id derived from the key, not on the text. An operator already asked about an
  overdue direction will not see the new wording for that direction, which is correct and
  worth stating where the change is recorded.
- The step still asks and nothing else — it never closes, proposes, lifts a gate, or now
  amends.
