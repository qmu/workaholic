---
created_at: 2026-08-29T07:20:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-closing-link-readable-as-the-corpus-grows
merge_policy:
verification_handoff: 
---

# Carry the degradation onto the survey rows

## Overview

PROPOSED. `survey-strategies.sh` derives `pace`, `dormant`, `quiescent`, `waiting_*` and
the `work_waiting` gate from the attribution walk. None of them may be derived from a walk
that did not complete, and `work_waiting` must not stand **open** on one — a gate that
cannot be read is not a gate, which is the rule this layer already holds itself to
(`inbox_unreadable`, `attribution_unreadable`). A degraded row is refused by name.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/keep-serving.md` — a gate that cannot be read is not a gate

## Key Files

- `plugins/workaholic/skills/strategy/scripts/survey-strategies.sh` — the row derivations and
  the refusal ladder.
- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — composes the survey; its
  precedence already has `unreadable` at the top and must keep answering it here.
- `plugins/workaholic/skills/propose/SKILL.md`, `plugins/workaholic/skills/strategy/SKILL.md` —
  the contracts stating what each reading means.
- `scripts/test-workflow-scripts.mjs`, `outputs/workflows/`.

## Implementation Steps

1. Read the walk's outcome from `attributed-work.sh` per row, and on a degraded read emit the
   derived readings as **unmade** rather than as false: `pace: unknown` (the value that already
   means *no reading*), `dormant: false`, `quiescent: false`, and null `waiting_*`.
2. **Refuse the row by name** — reuse the existing `attribution_unreadable` refusal rather than
   minting a second word for the same condition, and confirm it reaches `/propose`'s report
   unchanged.
3. **`work_waiting` must not stand open.** A degraded walk cannot prove the brake is clear, so
   the row is refused rather than proposed against. This is the failure the ask measured: a
   tick selected a direction on `waiting_count: 0` while two active missions and ten queued
   tickets cited it.
4. Confirm `direction-state.sh` answers `unreadable` for such a row through its existing
   precedence, with no second derivation and no new date arithmetic.
5. Leave every term that does **not** come from the walk byte-identical: `overdue`, `expiring`
   and `days_to_target` are date facts and must not move.
6. Hermetic cases: a healthy row unchanged byte-for-byte, and a degraded row refused with no
   `pace`/`dormant`/`quiescent` verdict and `work_waiting` not open.
7. Update `workaholic:propose` and `workaholic:strategy`, and regenerate `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A degraded walk yields no `pace: late`, no `dormant: true`, no `quiescent: true` and no
  `waiting_*` count on that row.
- `work_waiting` does not stand open on a degraded row; the row is refused by its existing name.
- `direction-state.sh` reads `unreadable` for that row.
- Every row whose walk completed is byte-identical to today.
- The date-derived terms are untouched.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A byte-diff of the survey over a healthy fixture, before and after.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No new refusal word is introduced for a condition that already has one.
- `Outputs Freshness` shows no diff after the rebuild.

## Considerations

- `quiescent` already reads `false` when the **residue** read was degraded (2026-08-28). This
  ticket adds the sibling term for the **attribution** read; state the two side by side in the
  skill so a later reader does not mistake one for the other or fold them together.
- Refusing a direction silences `/propose` for it, which is a real cost. It is accepted for the
  reason `inbox_unreadable` already records: proposing against a reading nobody can trust is
  worse than not proposing, and the degradation is now visible rather than silent.
