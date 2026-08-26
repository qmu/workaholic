---
created_at: 2026-08-26T02:23:47+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: turn-the-loop-at-mission-granularity
merge_policy:
verification_handoff: 
---

# Judge a whole mission, not one change

## Overview

`/propose` today judges **one evolutionary move** and opens an issue describing it. The
operator asks for a coarser proposal so the routine stops converging on housekeeping, and
for `/propose` to take on planning a **new mission** for the strategy. The move vocabulary
(`depth` | `breadth` | `contraction`) and the refusals built on it (`describing_move`,
`no_evolutionary_move`, the `## What this is chosen against` body floor) are what keep the
routine evolutionary; none of that is being dropped. What changes is the **scale of the unit
the move is declared over**: one mission, with its ordered ticket set, rather than one change.

## Policies

- `workaholic:planning` / `policies/scoping.md` — the unit of work is chosen deliberately
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — *The one thing it is for*, the body floor,
  and the sections that describe what a proposal contains
- `plugins/workaholic/skills/propose/scripts/open-proposal.sh` — the one writer; the body it
  stamps and the marker lines it emits
- `plugins/workaholic/commands/propose.md` — the entry-point contract
- `plugins/workaholic/skills/workaholify/routines/propose.md` — the `[Propose]` template's
  prompt, if the shape it names changes
- `scripts/e2e/loop-drill.sh` — `verify-propose` drills the brake with no network

## Implementation Steps

1. Restate the proposal's unit in `propose/SKILL.md`: one **mission** per proposal. The move
   is still declared and still chosen against something named — a move is now what the
   *mission* does to the Aim, not what one edit does.
2. Define the issue body's mission shape: a mission **title**, the **experience** it demands,
   and an **ordered ticket set**. Hold it to the ruled scale — roughly 7–8 tickets, with the
   follow-up repair mission of 3–4 available and a second concurrent mission refused.
3. Keep every existing refusal and make each hold at the new grain: `describing_move` (a
   mission that would only produce documentation about a build Aim), `no_evolutionary_move`
   (no mission can be named), and the `## What this is chosen against` floor — which now
   names the rival *mission*, not the rival edit.
4. Extend the body floor so an under-planned proposal is refused rather than published: a
   proposal naming fewer than two tickets is not a mission, and the refusal names the
   alternative, mirroring `mission/scripts/check-floor.sh`'s discipline.
5. Update `open-proposal.sh` only where the body shape it stamps requires it. Its contract
   does not move: `/propose` stays a **pure reader** of this tree whose only write is a
   GitHub issue.
6. Extend `verify-propose` in `scripts/e2e/loop-drill.sh` to cover the new floor with no
   network.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `/propose` proposal names a mission title, an experience and an ordered ticket set
- A proposal that cannot name at least two tickets is refused by name, not published
- `describing_move`, `no_evolutionary_move` and the chosen-against floor are stated at the
  mission grain and still refuse
- `/propose` writes no file, no commit, no branch and no pull request

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-propose`
- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The drill proves the new floor refuses, and `outputs/` is regenerated in the same commit

## Considerations

- **The fork worth naming: does `/propose` write the mission, or propose it?** "立案を担わせ"
  is *take charge of planning*, and planning is not writing. `/propose`'s pure-reader
  contract, the publish-tree seam, the ticket floor and the carry floor all live on the
  `/specificate` side; moving the write to `/propose` would duplicate every one of them and
  give the tree a second unattended writer. The recommendation is that `/propose` plans and
  `/specificate` writes — the granularity moves, the architecture does not. Recorded here as
  the reasoning, not as an unresolved question.
- The anti-housekeeping effect is expected to come from the **scale** as much as from the
  refusals: a mission-sized proposal cannot be "add a test" without saying so out loud.

## Final Report

Development completed as planned. `/propose`'s unit is now a mission: `propose/SKILL.md` opens
with *The unit is a mission, not a change*, the body floor in `open-proposal.sh` gained
`## Experience` and `## Tickets` beside the three commitment sections, and a `## Tickets`
section naming fewer than two tickets is refused `under_planned` with the alternative named —
`mission/scripts/check-floor.sh`'s discipline applied at the proposing seam. `describing_move`,
`no_evolutionary_move` and the chosen-against floor are restated at the mission grain and still
refuse. `commands/propose.md` carries the same contract; `verify-propose` drills both new
refusals with no network.

The fork the ticket named is settled the way its Considerations recommended, and the reasoning
is recorded in the SKILL rather than left implicit: **`/propose` plans, `/specificate` writes**.
Moving the write here would duplicate the publish-tree seam, the ticket floor, the carry floor
and the pull request, and would give the tree a second unattended writer.

The routine template `workaholify/routines/propose.md` is **unchanged**, deliberately: it names
no post format (`/propose` posts nothing) and its environment did not move, and the templates
are pinned byte-identical by the suite.

### Discovered Insights

- **Insight**: The floor is a floor and not a ceiling, and a test pins that.
  **Context**: The ruled scale is "roughly 7–8 tickets", which no script can check; a set of
  twelve passes the write floor on purpose. Adding a ceiling here would be the first time this
  script graded a proposal rather than checking presence.
- **Insight**: `no_move` is refused before the body is read, so the drill's existing
  move-floor case survived the new headings untouched.
  **Context**: The argument-validation order in `open-proposal.sh` is load-bearing for every
  fixture that hands it a partial body; a later reader adding a check should keep cheap
  argument refusals ahead of body parsing.
- **Insight**: A `## Tickets` count has to be scoped to its own section.
  **Context**: Ordered-list lines appear throughout a proposal body; counting them globally
  would let prose satisfy the mission floor.
