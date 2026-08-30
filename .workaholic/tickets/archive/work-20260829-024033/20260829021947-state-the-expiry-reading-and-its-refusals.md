---
created_at: 2026-08-29T02:19:47+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: warn-a-direction-before-its-date-silences-the-loop
merge_policy:
verification_handoff: 
---

# State the expiry reading and its refusals

## Overview

PROPOSED. The documentation half, in the same change as the behaviour — this
repository's own rule, and outdated documentation is a defect rather than a
backlog item. `workaholic:propose`, `workaholic:strategy`, `workaholic:moderate`
and `CLAUDE.md` state the reading and, as importantly, **what was refused and
why**:

- a machine **re-dating or closing** a direction on this reading — the artifact
  keeps its three writers, and a run never amends a direction on its own reading;
- folding `expiring` into `pace` as a **fourth value** — one field answering two
  questions is how the two drift, the reasoning `overdue` already records;
- a **tunable threshold** in place of the window already justified on the row —
  a new constant would be a number nobody can defend, where `$window_days` is
  the window the judgment is already made against.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/change-history.md` — the record states current behaviour and names what was refused

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — the reading beside `pace`,
  `overdue`, `dormant` and `quiescent`, and the statement that it gates nothing.
- `plugins/workaholic/skills/strategy/SKILL.md` — the lifecycle reading and its
  precedence rung.
- `plugins/workaholic/skills/moderate/SKILL.md` — the `direction-health` step's
  fourth question key and its holds.
- `CLAUDE.md` — the direction-layer paragraph and the `/moderate` row.
- `docs/loop-drill-runbook.md` — already touched by ticket 7; confirm it agrees.

## Implementation Steps

1. Read what each document says today about `overdue`, `dormant` and `quiescent`
   — those three are the register and the length to match. State the reading,
   its boundary, and its refusals; do not restate the implementation.
2. `workaholic:propose`: the term on the row, computed before `refusal`, emitted
   on eligible and refused rows alike, gating nothing — with the `pace` refusal
   named as the reason it gates nothing.
3. `workaholic:strategy`: the precedence rung and why it sits between `overdue`
   and `dormant`, and the leaving carried onto it at no extra read.
4. `workaholic:moderate`: `direction-expiring:<slug>`, its addressee, its holds,
   and the one-direction-one-question rule.
5. `CLAUDE.md`: the direction-layer paragraph and the `/moderate` row, in that
   file's voice — current behaviour, with the refusals named.
6. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) and verify
   (`verify.mjs`, `validate-metadata.mjs`), since skill bodies moved.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- All four documents describe the shipped behaviour, with no statement left
  describing the pre-change layer.
- Each names the three refusals above with its reason, not merely the decision.
- `outputs/` is regenerated and matches a fresh build.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/build-plugins/validate-metadata.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The `Outputs Freshness` CI workflow is green — a hand-edited `outputs/` fails
  it by design.

## Considerations

- The risk in a documentation ticket at the end of a mission is that it restates
  the implementation instead of the **decision**. What a later reader needs is
  the boundary (`0 <= days <= window`), why the window is not a new constant, and
  what a machine may not do with the reading.
- Keep the `CLAUDE.md` addition proportionate: it is one reading in an existing
  layer, not a new subsystem.

## Final Report

Development completed as planned. `workaholic:propose` gains *Expiring: the date is about to
arrive* beside `pace` / `overdue` / `dormant` / `quiescent`; `workaholic:strategy` carries the
new rung, the answer table and the argument for its position against **both** neighbours;
`workaholic:moderate` and its `reference/workflow.md` carry the fourth question key, its
addressee and its holds; `CLAUDE.md` carries the reading in the direction-layer paragraph, the
key in the `/moderate` row and the drill in the drill list; and `docs/loop-drill-runbook.md`
already agreed (§5j-ter, written with the drill).

Each document names the three refusals with its reason rather than the decision alone: a
machine **re-dating or closing** a direction on the reading (the artifact keeps its three
writers, and a run never amends on its own reading), folding `expiring` into `pace` as a
**fourth value** (one field answering two questions is how the two drift), and a **tunable
threshold** in place of the window already justified on the row (a fresh number is one nobody
can defend, where `$window_days` is the window the judgment is already made against).

`outputs/` regenerated; `build.mjs`, `verify.mjs`, `validate-metadata.mjs` and
`layout-doctor.sh` all clean, and the hermetic suite is 4702 passed / 0 failed.

### Discovered Insights

- **Insight**: the reading touched two generated copies of two scripts across six bundled
  skills, and nothing warns you at commit time.
  **Context**: `survey-strategies.sh` and `direction-state.sh` ride the closure of `catch`,
  `create-ticket`, `drive`, `mission`, `ship` and `story`, so a change to either leaves twelve
  files in `outputs/` stale until `build.mjs` runs. The `Outputs Freshness` CI workflow is the
  only thing that catches it — which is why the regeneration belongs in this ticket rather than
  in the ticket that edited the script.
- **Insight**: the documentation set for this layer is closed, and it is worth knowing that.
  **Context**: a grep for the lifecycle answer set across `docs/`, `README.md` and
  `.workaholic/README.md` finds only the drill runbook. The four documents this ticket names
  really are all of them, so the risk in a change here is a statement left describing the
  pre-change layer inside those four, not one hiding somewhere else.
