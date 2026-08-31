---
created_at: 2026-08-31T10:24:24+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260831102424-name-the-impaired-steps-on-every-root.md
mission: name-the-steps-a-tick-could-not-read
merge_policy:
verification_handoff: 
---

# State the impairment rule where the voice is defined

## Overview

PROPOSED. `render-tick-post.sh`'s header is where this tick's voice is defined — what counts
as a change, why the diff exists, what each gate is and which retired shape it is not. The
rule this mission adds is a **fourth gate and a clause outside the diff**, and both are
exactly the kind of decision that gets re-argued and reverted when only the code carries it:
the repository has already reversed one rename on a mistaken assumption about a dedup key.

This ticket states the rule once, in the three places a later reader will actually look, and
records the reasoning that keeps it distinguishable from the two status roots this
repository retired.

## Policies

- `workaholic:development` — decision history and rationale are the durable artifact
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the header block that
  names each gate and its retired counterpart; the fourth gate goes in beside them.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — §"The post this step
  produces" (the gate list) and the run-report row schema.
- `plugins/workaholic/skills/moderate/SKILL.md` — the degraded-read discipline
  ("a degraded read is reported and skipped, never half-applied"), which until now stopped
  at the tick log.
- `CLAUDE.md` — the `/moderate` row, which enumerates the tick's gates and its retired
  status roots.

## Implementation Steps

1. In `render-tick-post.sh`'s header, add the fourth gate beside the three that are there,
   stating: the **statement** is on every root that posts (outside the diff, because a
   standing impairment said once and then dropped is the defect), and the **post** is on
   change (inside the diff, because an unchanged answer restated hourly is what
   `📦 Release Preparation` was retired for).
2. State the boundary the reading draws: `degraded` and `blocked` are impairment,
   `skipped` is not, and `ok`/`filed` are not. One sentence, where the derivation lives.
3. In `reference/workflow.md`, update the gate list and the post shape so the two documents
   cannot disagree about what a root carries.
4. In `SKILL.md`, extend the degraded-read discipline from *reported in the log* to
   *reported where the operator reads*, citing the measurement: 24 of 25 ticks impaired,
   six steps, found four days later by asking. A rule with its measurement attached is the
   one that survives.
5. In `CLAUDE.md`, add the gate to the `/moderate` row's enumeration and record, in one
   clause, why this does not reverse either status-root retirement.
6. Regenerate `outputs/` and the policy index, and re-run the drift pins.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `render-tick-post.sh`'s header names the fourth gate and states the outside-the-diff /
  inside-the-diff split with its reason.
- `reference/workflow.md`'s gate list and post shape match the shipped renderer.
- `SKILL.md` states that a degraded read is reported where the operator reads, with the
  measurement attached.
- `CLAUDE.md`'s `/moderate` row names the gate and why it is not a reinstated status root.
- No document still describes the root as carrying only changes and questions.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- A read of each of the four documents against the shipped behaviour.

**Gate** — what must pass before approval:

- All four documents updated in the same change — an outdated document is a defect by this
  repository's own rule, and this mission changes what the post means.

## Considerations

- The tempting shortcut is to state the rule only in the script header, since that is where
  the mechanism is. It is refused: `CLAUDE.md`'s `/moderate` row is what a future proposal
  reads before touching the tick, and a gate missing from it will be re-litigated.
- This ticket writes prose and no mechanism, which is the shape `/propose` refuses as a
  `describing_move`. It is admissible here because it is **not the move** — it is the
  documentation obligation every change in this repository carries, scoped to one mission
  whose other four tickets are mechanism.
