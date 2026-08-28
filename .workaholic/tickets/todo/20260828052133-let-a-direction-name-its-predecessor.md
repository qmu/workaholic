---
created_at: 2026-08-28T05:21:33+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-end-a-turn-of-the-loop-not-its-stop
merge_policy:
verification_handoff: 
---

# Let a direction name its predecessor

## Overview

When the operator announces a new direction as the successor of a named one, the successor
should inherit the predecessor's visibility through the relation that already exists: its
`feedback:` line carries the predecessor's own refs, so `attributed-work.sh` reads the
predecessor's landed work and residue as the successor's from its first hour. A machine carries
what the operator announced by explicit slug; it never authors a direction.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 9b, the strategy form
- `plugins/workaholic/skills/specificate/SKILL.md` — the strategy form and the announcement table
- `plugins/workaholic/skills/feedback/scripts/ask-feedback-line.sh` — the one writer of that line
- `plugins/workaholic/skills/strategy/scripts/create.sh` — unchanged; it must not learn about succession
- `plugins/workaholic/skills/strategy/scripts/list.sh` — the set a named predecessor is matched against
- `scripts/test-workflow-scripts.mjs` — the refusals and the carry's wiring point

## Implementation Steps

1. Recognise a **successor announcement**: the strategy form's ask names an explicit predecessor
   slug. A title or a paraphrase never matches — the same explicit-slug rule every lifecycle
   announcement already holds.
2. Confirm the named predecessor against step 5b's set; read its own `feedback:` refs through the
   reader that already reads them.
3. Include those refs in the successor's line, emitted through `ask-feedback-line.sh` — still the
   one writer of that line. `create.sh` is unchanged and learns nothing about succession.
4. Refuse by name, writing nothing: `strategy_not_found`, `predecessor_active` (a live direction is
   not a predecessor), `no_predecessor`.
5. Report the succession in the run report and the pull-request body — which predecessor, and how
   many refs were carried.
6. Leave every other rule intact: the three-part bar, the assignee resolution, and the
   never-auto-merge rule for a strategy-touching publish.
7. Pin in the suite that the carry is wired at the ask line and **not** inside `create.sh`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A successor announcement naming an explicit predecessor slug creates a strategy whose `feedback:` refs include the predecessor's own
- `strategy_not_found`, `predecessor_active` and `no_predecessor` each refuse by name and write nothing
- `create.sh` is byte-identical and the strategy artifact still has exactly three writers
- The publish still does not auto-merge

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-succession` (ticket 7)

**Gate** — what must pass before approval:

- Matching is by explicit slug only, in the diff as well as in the prose
- No new field, no new relation, and the retired `strategy:` relation stays retired

## Considerations

- The successor's Aim, Schedule and Assignee stay the operator's words; only the citation is carried.

## Final Report

Development completed as planned.

A *created* announcement that names an explicit predecessor slug takes the strategy form
unchanged in every part, plus that predecessor's own `feedback:` refs — read through
`strategy/scripts/read.sh`, composed through `feedback/scripts/ask-feedback-line.sh`
(`--refs-only`, the one writer of that ref set), and handed to `create.sh` as the fifth
argument it has always taken. `create.sh` is byte-identical and learns nothing about
succession. Refusals: `strategy_not_found`, `predecessor_active`, `no_predecessor`. The
succession is reported as `successor_of:<predecessor>:<n>` in the run report and the
pull-request body; the publish still does not auto-merge.

### Discovered Insights

- **Insight**: a successor announced beside the record that announced it will often cite the
  same ref twice.
  **Context**: `ask-feedback-line.sh` collapses a repeated ref, order preserved. A doubled ref
  is noise in every reader of the relation, and collapsing it at the one writer is cheaper
  than teaching each reader to tolerate it.
- **Insight**: a fresh successor carrying a closed predecessor's refs reads `arrived` when the
  inherited work is all in, and `live` when something is still in flight.
  **Context**: neither is `dormant`, which is the reading the carry exists to prevent. Pinning
  a single expected state would have been wrong; what is pinned is the absence of `dormant`
  plus both honest readings.
