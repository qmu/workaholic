---
created_at: 2026-08-27T01:20:32+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-the-units-the-loop-already-finished
merge_policy:
verification_handoff: 
---

# Give a unit's close its own reported outcome

## Overview

The `review` route reports **which route it took** and never **whether the merge landed**. A run
that opened a pull request and was refused the merge produces the same report line as one that
merged — so the failure is invisible at the only surface that records the run.

`branching/scripts/merge-reason.sh` already classifies the refusal into five honest words
(`merge_not_allowed`, `head_moved`, `session_type_cannot_merge`, `merge_forbidden`,
`merge_failed`), each of which is a different next action by that script's own header. The
vocabulary is correct and does not move; what is missing is that the route **carries it into the
run report**, per unit.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — an outcome is reported in its own
  vocabulary, never collapsed

## Key Files

- `plugins/workaholic/skills/drive/reference/routing.md` — §6's `review` route: reads
  `gate-decision.sh`, then `PUT .../pulls/{n}/merge` through `gh-rest.sh`. The place the outcome
  is produced.
- `plugins/workaholic/skills/drive/SKILL.md` — §6 and §7. §7 is the run-report contract; the
  per-unit line is defined there.
- `plugins/workaholic/skills/branching/scripts/merge-reason.sh` — the refusal vocabulary. **Read
  its header before touching anything**: the reasons are deliberately distinct next actions, and
  the session-type rung is keyed on the message with the status as its fallback.
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the other caller of the same
  ladder, for `WORKAHOLIC_AUTO_MERGE`. Its reporting of `merged` / `merge_reason` is the existing
  shape to follow rather than invent a second one.

## Implementation Steps

1. Read §7's per-unit report contract and establish what a unit's line carries today, so the
   merge outcome is added to it rather than reported beside it.
2. Make the `review` route record its merge attempt's result per unit: `merged`, or the
   `merge-reason.sh` word. A route that never attempted the merge (a `hard`/`confirm` scan finding
   held the pull request) reports that as its own outcome — **not** as a merge failure.
3. Carry it into §7's report line so the run report names it for every `review` unit.
4. Document the addition in `drive/SKILL.md` §6/§7 and `drive/reference/routing.md` in the same
   change (CLAUDE.md's *Update the docs in the same change*).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `review` unit's report line names `merged` or the refusal word that stopped it.
- A unit whose merge was never attempted because a `hard`/`confirm` finding held its pull request
  is reported as that, distinctly from a refused merge.
- `merge-reason.sh`'s five words are unchanged in derivation and format.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Exercise `merge-reason.sh` over each rung's response text and confirm the report renders that
  word.

**Gate** — what must pass before approval:

- The hermetic suite passes; the scan-held and refused cases render differently.

## Considerations

- The `auto` route already distinguishes "shipped" from "demoted, with the gate that caused it".
  Reuse that wording rather than minting a parallel vocabulary for the same distinction.
- `/specificate`'s own `WORKAHOLIC_AUTO_MERGE` publish hits the identical refusal — pull request
  #625 in the measurement is a `[Proposal]`, not a driven unit. That seam is **out of this
  ticket's scope** (the ask names the `review` route), but the shape chosen here should not make
  the same fix there harder.
