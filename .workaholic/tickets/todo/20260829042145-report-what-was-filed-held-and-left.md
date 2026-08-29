---
created_at: 2026-08-29T04:21:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-s-own-findings-become-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Report what was filed, held and left

## Overview

PROPOSED. Three outcomes must never render alike: a finding the tick **filed** as work,
one the brake **held**, and one **left to a person** because it needs a ruling. Each is
a different fact about the loop and asks a different thing of the reader, and collapsing
them is exactly what made the tick's debt invisible — `0 retired` hour after hour with
nobody told.

Three surfaces, each with its own audience: the step's log-facing **`summary`** (written
for a maintainer diagnosing the tick), its **`event`** (a repository event for the
`🔎 Moderation` root — and **empty** until the agent has acted, `standing-rulings`' rule
for `standing-rulings`' reason), and the **run report**. A step with no event renders no
root line, which is the independent guard against a nothing-happened line reaching the
root even when the diff calls it changed.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-behavior.md` — a degraded read is named, never rendered as quiet

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-file-findings.sh` — emits `summary`,
  `event` and the per-candidate detail.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — renders the root
  line from `event`; the diff against the previous tick is what stops an hourly restatement.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — assembles the run report.
- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — the precedent for
  reporting `delivered` / `held_count` / `candidates` with a **named** reason for zero
  (`cap_spent` distinguished from `cap_unbounded`); copy that discipline.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the contract.

## Implementation Steps

1. Read `step-human-checkin.sh`'s reporting block: it names the reason it delivered
   nothing and distinguishes *the budget worked* from *our own degradation*. That
   distinction is the model for `held` versus an unreadable brake.
2. Emit per tick: `filed` (each issue by number and the finding it carries), `held`
   (each candidate and **which** open issue held it), `left` (each `needs_ruling`
   finding, counted, since those reach a person through their own question), and a
   named reason when nothing was filed — `brake_held`, `brake_unreadable`,
   `all_already_filed`, `no_candidates` — never one word for all four.
3. Make the summary **stable**: every term a function of the candidate set and the brake
   state alone, so an unchanged hour renders an identical summary and the diff suppresses
   it. No timestamps, no counts that move for reasons the reader cannot see
   (`inbound-sweep`'s embedded timestamp is the measured failure here).
4. Supply the `event` only for a real repository event — an issue filed. A tick that
   filed nothing supplies none and renders no root line.
5. Write the run-report line: what was filed, what the brake held, what was left. State
   in the contract that a run naming a candidate and reporting no outcome for it is
   **non-conformant on its face** — the connector retry's enforcement, same reason.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Filed, held and left render as three distinct statements on all three surfaces.
- A tick that filed nothing names **why**, from a closed set of reasons.
- An unchanged reading renders an identical summary and no root line.

**Verification method** — the commands/tests/probes that prove them:

- Ticket 8's drill: consecutive ticks whose second is a no-op produce no second root line.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The suite is green, and the no-op tick was observed to render nothing.

## Considerations

- The `event` is the one place it is easy to be dishonest: the agent files after `run.sh`
  returns, so an `event` written by the step would announce an act that has not happened.
  Empty is correct; ticket 3 already states it.
- `left` is a count, not a list. Those findings reach a person through their own
  questions, and re-listing them here is the report addressed to nobody this repository
  has twice retired posts for.
