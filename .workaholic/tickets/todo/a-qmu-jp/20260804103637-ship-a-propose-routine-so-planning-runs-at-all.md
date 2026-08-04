---
created_at: 2026-08-04T10:36:37+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-an-fb-reach-a-reviewable-proposal
merge_policy:
---

# Ship a propose routine so planning runs at all

## Overview

`/workaholify` ships exactly three routine templates — `fb`, `drive`,
`merged-pr`. There is no `propose` routine, so the only seam that turns
feedback into a mission with its ticket set is never invoked in the fleet.
CLAUDE.md still describes `/propose` as "the 15-minute cron entry", but the
fleet moved to Claude Code Web routines and none of them run it. This is why a
feedback record can sit on `main` indefinitely without ever becoming reviewable
work, which is the gap the linked records describe from the outside.

Add a fourth routine template that runs the proposal batch, and correct the
documentation that still claims a cron runs it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/delivery.md` — how a standing process reaches production

## Key Files

- `plugins/workaholic/skills/workaholify/routines/` — the template set; the new
  `propose.md` lands here beside `fb`/`drive`/`merged-pr`
- `plugins/workaholic/skills/workaholify/SKILL.md` — the survey/provision prose
  that enumerates the templates
- `plugins/workaholic/commands/propose.md` — the batch this routine invokes
- `CLAUDE.md` — the `/propose` row still says "15-minute cron entry"; update in
  the same change per the docs rule

## Implementation Steps

1. Decide the trigger with the developer's intent in view: a schedule, or an
   event on FB issue creation. Record the choice and its reason in the template
   itself, as the other three templates do.
2. Write `routines/propose.md` following the existing template shape
   (frontmatter `id`/`name`/`trigger`/`model`/`allowed_tools`/`mcp`, then a
   `## Prompt` section). Reuse `drive.md`'s precondition block — git identity,
   clean base, plugin loaded — since the same failure modes apply.
3. State the batch's own contract in the prompt: silence is a valid outcome,
   never prompt, and the cursor advances only on success.
4. Fold the new template into `compare-routines.sh`'s expectations so a repo
   missing it is reported as missing rather than as conforming.
5. Update `CLAUDE.md` and `workaholify/SKILL.md` to describe the routine set as
   four templates, and drop the stale cron claim.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `propose` template exists in `routines/` and is structurally valid against
  the same shape as the other three
- `/setup-routines` reports the template as available, and reports its absence
  in a repository as a missing routine rather than silence
- No document still describes `/propose` as a cron entry

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `node scripts/test-workflow-scripts.mjs`
- `/setup-routines` against this repository, reading the reported template set
- `grep -rn "15-minute cron" CLAUDE.md docs/ plugins/` returns nothing

**Gate** — what must pass before approval:

- The trigger choice is recorded with its reason, not left implicit

## Considerations

- The trigger is a real design decision, not a mechanical one: an FB-event
  trigger gives a per-FB proposal (what the lifecycle wants) but proposes from
  one record at a time; a schedule batches but decouples the proposal from the
  FB that caused it. The sibling ticket on verdict reporting depends on which
  is chosen.
- A routine is a standing outward-facing process, so creating it is confirmed
  verbatim by a human — this ticket ships the template, not the live routine.
