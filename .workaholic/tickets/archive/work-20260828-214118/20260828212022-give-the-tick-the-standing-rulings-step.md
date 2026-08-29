---
created_at: 2026-08-28T21:20:22+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: put-the-loop-s-standing-rulings-on-one-pull-request
merge_policy:
verification_handoff: 
---

# Give the tick the standing-rulings step

## Overview

PROPOSED. Give the hourly tick the step that drafts the ruling set, bounded to one open
ruling pull request at a time so the operator is never handed two competing diffs about
the same subjects, and silent on a tick that drafted nothing.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-standing-rulings.sh` — new step
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the `STEPS` list gains it
- `plugins/workaholic/skills/moderate/scripts/step-closable-missions.sh` — the precedent
  for a step whose act needs a publish tree and is therefore handed to the agent
- `plugins/workaholic/skills/propose/scripts/list-open-proposals.sh` — the `open_proposal`
  brake's shape: read off the open pull requests, no cursor, no stored state
- `plugins/workaholic/skills/moderate/SKILL.md`, `CLAUDE.md` — the step is documented in the
  same commit

## Implementation Steps

1. Add `step-standing-rulings.sh` and register it in `run.sh`'s `STEPS`, placed beside
   `direction-health` and `undrivable-units` — the two steps whose findings it settles.
2. Draft **at most one open ruling pull request at a time**, in the `open_proposal` brake's
   shape: derived from the open pull requests the loop itself opened, with **no cursor and
   no stored state**. A ruling pull request already open means this tick drafts nothing.
3. Supply an **`event`** only when the tick actually drafted something — a step with no
   event renders no root line, which is what keeps an hourly tick from restating an
   unchanged answer.
4. Write **nothing but its own tick-log line**. Every artifact write happens in the publish
   tree the previous two tickets opened, exactly as `closable-missions` hands its
   tree-writing act to the agent rather than performing it inside `run.sh`.
5. A **degraded read drafts nothing** — a ruling that could not be read is not a ruling —
   and is reported by name.
6. Never reach `plan-units.sh`: the survey runs the living migrations and **stages** what
   they converge, and a step whose contract is *writes nothing* may not reach it through
   something that writes.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The step is registered in `STEPS` and contributes a report line on every tick.
- With a ruling pull request open, the tick drafts nothing.
- A tick that drafted nothing supplies no `event` and renders no root line.
- A degraded read drafts nothing and is named.
- The step's own text never reaches `plan-units.sh`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Two consecutive ticks over one fixture, asserting the second drafts nothing.

**Gate** — what must pass before approval:

- The tick's *writes nothing but its own log line* contract still holds, asserted over the
  checkout after a run.

## Considerations

- The brake is deliberately read off GitHub rather than stored: a cursor is a second source
  of truth about what is in flight, and this repository has refused one at every equivalent
  seam.

## Final Report

Development completed as planned.

`step-standing-rulings.sh` is registered in `run.sh`'s `STEPS` beside `undrivable-units` and
`direction-health` — the two steps whose findings it settles — and contributes a report line
on every tick. It reads the brake first (`list-open-rulings.sh`, new: the open `[Ruling] `
pull requests, in `list-open-proposals.sh`'s shape, no cursor and no stored state) and drafts
nothing when one is open; it reads the candidate set second and hands it back in
`needs_agent`, because the judgement is the run's and no script may derive one. It writes
nothing anywhere, never reaches `plan-units.sh`, and a degraded read of either half is named
and drafts nothing. `moderate/SKILL.md`, its `reference/workflow.md` and `CLAUDE.md` moved in
the same commit.

### Discovered Insights

- **Insight**: the `event` cannot be honest here and is therefore **always empty**, which is
  `step-unanswered-asks.sh`'s stated divergence for the same architectural reason: the agent
  acts on `needs_agent` only after `run.sh` returns, so at the moment the step's line is read
  nothing has been drafted. The ticket's "supply an `event` only when the tick actually
  drafted something" is satisfied trivially and honestly rather than by guessing.
  **Context**: any future step whose act is the agent's meets the same wall.
- **Insight**: the brake needs the drafted pull request to name its subjects, so
  `draft-standing-rulings.sh` writes one `ruling: <kind> / subject: <subject>` line into the
  body — visible text, in `/propose`'s marker shape, never an HTML comment. The next ticket's
  question suppression reads the same line, so the suppression is derived rather than stored.
  **Context**: one marker serves the brake and the suppression; a second would drift.
