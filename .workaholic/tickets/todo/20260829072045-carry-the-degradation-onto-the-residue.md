---
created_at: 2026-08-29T07:20:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-closing-link-readable-as-the-corpus-grows
merge_policy:
verification_handoff: 
---

# Carry the degradation onto the residue

## Overview

PROPOSED. `mission-strategy.sh` answers *which direction does this mission belong to* by
composing the same walk, and `unattributed-work.sh` composes that into the residue. On a
degraded walk a citing mission is indistinguishable from an unattributed one, so the residue
names work the tree already attributes — and that residue is what `/moderate`'s
`direction-arrived:<slug>` question and the standing-rulings draft both read. A blind walk
currently asks the operator to rule on attributions that already exist.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/keep-serving.md` — a half-read leaving is never rendered as a whole one

## Key Files

- `plugins/workaholic/skills/strategy/scripts/mission-strategy.sh` — the per-mission answer.
- `plugins/workaholic/skills/strategy/scripts/unattributed-work.sh` — the residue; it already
  has the `readable: false` + null-counts shape.
- `plugins/workaholic/skills/strategy/scripts/closing-residue.sh` — the assembly that carries
  the residue into the leaving; **read only** unless a term must be passed through.
- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh`,
  `list-standing-rulings.sh` — the consumers; changed only if they read a term that moves.
- `scripts/test-workflow-scripts.mjs`, `outputs/workflows/`.

## Implementation Steps

1. `mission-strategy.sh` must not answer *no strategy* from a degraded walk. Give it the
   walk's outcome and let it report unreadable-for-that-mission instead, keeping the existing
   distinction between *belongs to no direction* and *could not be attributed* — the property
   that reader was written to preserve.
2. `unattributed-work.sh` must not **name** a citing mission as unattributed on a degraded
   walk: report `readable: false` with the reason and **null** counts, which is the shape it
   already uses, rather than a residue that over-reports into an operator's question.
3. Confirm `closing-residue.sh` carries that block's own `readable` through to its top-level
   reason, as its existing contract requires (`waiting_unreadable:<reason>` and its siblings) —
   no second assembly, no re-read.
4. Confirm the two consumers behave: `direction-arrived:<slug>` already yields **no reading and
   no question** on a degraded residue, and the standing-rulings draft must reach no writer with
   a candidate it could not attribute. Change them only if a term they read actually moved.
5. Leave a **non-degraded, non-empty** residue exactly as it is: an unattributed mission is
   still an unattributed mission, and suppressing those would be a different defect of the same
   shape.
6. Hermetic cases: a healthy residue byte-identical; a degraded walk producing a named
   unreadable residue rather than a list; no question reaching the operator from it.
7. Update `workaholic:strategy`, regenerate `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- On a degraded walk, no citing mission is named as unattributed anywhere.
- `unattributed-work.sh` reports `readable: false` with a reason and null counts.
- `closing-residue.sh` names the failed source rather than rendering an empty leaving.
- No `direction-arrived` question and no standing-rulings candidate is produced from a degraded
  residue.
- A healthy residue — empty or not — is byte-identical to today.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-residue` and `verify-rulings` still green.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No second walker, no relation and no field on any artifact is introduced.
- `Outputs Freshness` shows no diff after the rebuild.

## Considerations

- The residue is lossy by construction and says so; this ticket must not be read as making it
  exhaustive. What it changes is only that a walk we could not complete stops being reported as
  a walk that found nothing.
- `verify-residue` deliberately builds its degraded case by removing `mission-strategy.sh`
  from a copy of the plugin tree. If that reader's outcome shape changes here, that drill row
  needs re-checking rather than re-writing.
