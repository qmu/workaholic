---
created_at: 2026-08-27T05:22:41+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-and-retire-what-the-loop-already-proved-finished
merge_policy:
verification_handoff: 
---

# Add the /moderate step that retires a proved claim

## Overview

PROPOSED. `retire-claim.sh` (ticket 4) is the writer; this ticket adds its **only** caller —
a `/moderate` step beside `undelivered-units`. The step re-proves each `superseded` row in the
tick's own read of the oracle, retires what the re-proof confirms, and reports every
retirement and every refusal by name. It **asks no question** — a retirement is not a person's
business — and writes nothing into the tree but its own log line.

This follows the precedent `closable-missions` set on 2026-08-24: the tick closes what the
step proved, with the proof re-taken at the moment of the act rather than trusted from an
earlier read.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the maintenance tick's contract

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — **new**; the step.
- `plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh` — the step it runs
  beside; read it for the `list-claims.sh`-not-`plan-units.sh` rule and the reporting shape.
- `plugins/workaholic/skills/moderate/scripts/step-closable-missions.sh` — the re-prove-then-act
  precedent, including why the survey may not be composed here.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — invokes every step; the step is added
  to the ordered list.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step count and the step's record.
- `CLAUDE.md` — the `/moderate` row.

## Implementation Steps

1. Read `step-undelivered-units.sh` and `step-closable-missions.sh` in full, including their
   headers' reasons for reading `list-claims.sh` rather than `plan-units.sh` — the survey runs
   the living migrations and **stages** what they change, and a step whose contract is *writes
   nothing into the tree* may not reach it through something that writes.
2. Read the oracle once in the step, take every row whose verdict is `superseded`, and
   **re-prove** it at the moment of the act rather than trusting an earlier read.
3. Call `retire-claim.sh` per confirmed row. A row the re-proof rejects is **reported, not
   retired**.
4. Report per row: retired (with the three acts' outcomes) or refused (with the reason).
5. Ask **no** question — the step's `needs_agent` carries nothing for the check-in.
6. Write one log line through `log-append.sh` like every other step; nothing else in the tree.
7. Update the step count in `moderate/SKILL.md` and `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every `superseded` row confirmed by the re-proof is retired; every rejected one is reported.
- The step asks no question and contributes nothing to the check-in.
- The step reads `list-claims.sh`, never `plan-units.sh`.
- The step writes nothing into the tree but its own log line.
- `run.sh` invokes it and it contributes a report line whether or not it retired anything.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire` (ticket 7)
- `git status` clean after a step run over a fixture — the check that caught
  `closable-missions` leaving a modified mission in the index.

**Gate** — what must pass before approval:

- No `plan-units.sh` call anywhere in the step's reach, and the tree is unmodified after a run.

## Considerations

- The step is the writer's only caller, deliberately: one caller is what keeps the retirement's
  bounds checkable.
- A degraded oracle read is reported `degraded` by name and retires nothing — a proof that
  could not be read is not a proof.
