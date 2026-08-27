---
created_at: 2026-08-27T01:20:33+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-the-units-the-loop-already-finished
merge_policy:
verification_handoff: 
---

# Make the connector retry a step of the route

## Overview

`rules/shell.md`'s 2026-08-23 qualification permits exactly one retry of
`session_type_cannot_merge` through `mcp__github__merge_pull_request` — one tool, one named
precondition, one act, behind REST and never replacing it. A script cannot call an MCP tool, so
that retry lives **only in prose**: the closing act is a sentence the agent may simply not take,
and nothing anywhere records whether it was taken.

The measurement is what that costs: four pull requests the loop opened on 2026-08-26 were green
and unmerged at 2026-08-27, with `ok` reported over all of them.

Make the retry a **named, mandatory step of the route with its own reported outcome**, so a run
that skipped it is visibly non-conformant. This is the shape the Open-Decision contract already
uses for a prose rule no script can enforce (`drive/reference/ticket-workflow.md` §1): no
mechanical check tells a real attempt from a claimed one, and what it buys is that a report
naming no attempt is visibly wrong.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — the outcome of every attempt is reported
  by name

## Key Files

- `plugins/workaholic/rules/shell.md` — *The one qualification*. The permission's exact bounds:
  one tool, one named precondition, one act; reads, writes and pull-request creation stay REST.
  **Read the whole section** — the bounds are the ticket, and widening them is out of scope.
- `plugins/workaholic/skills/drive/reference/routing.md` — §6's `review` route, where the step
  belongs.
- `plugins/workaholic/skills/drive/SKILL.md` — §6 and §7; the run-report contract that carries the
  retry's outcome.
- `plugins/workaholic/skills/branching/scripts/merge-reason.sh` — the one refusal this retry may
  answer. Every other word is reported as-is and never retried.
- `plugins/workaholic/skills/drive/reference/ticket-workflow.md` — the Open-Decision contract's
  precedent for a prose rule made visibly checkable.

## Implementation Steps

1. Read `rules/shell.md`'s qualification in full and write down its exact bounds, so the step
   authorizes nothing beyond them.
2. Write the retry as a numbered step of the `review` route in `drive/reference/routing.md`:
   preconditioned on `merge_reason == session_type_cannot_merge` and on nothing else, at most
   once, through `mcp__github__merge_pull_request` and no other tool.
3. Give it a reported outcome of its own in §7 — merged through the connector, or the pull request
   left open with **both** refusals named (the REST one and the connector's). A run that reports
   `session_type_cannot_merge` and no retry outcome is non-conformant on its face.
4. State the same bounds in `drive/SKILL.md` §6 and in `CLAUDE.md`'s `/implement` row, in this
   change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The retry is a numbered step with a stated precondition, a stated bound of one attempt, and a
  reported outcome.
- No refusal other than `session_type_cannot_merge` reaches the retry.
- A report carrying `session_type_cannot_merge` and no retry outcome is identifiable as
  non-conformant from the report alone.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the `gh issue|pr|repo` ban must still hold)
- Read the shipped route against `rules/shell.md` and confirm the bounds match word for word.

**Gate** — what must pass before approval:

- The hermetic suite passes and no script gained an MCP call.

## Considerations

- The cost is stated rather than hidden: this moves one step into the calling agent, against this
  repository's no-inline-shell grain. `rules/shell.md` already accepted that narrowly; do not
  widen it here to cover reads or pull-request creation.
- A merge through the connector is measured only in an **interactive** session; a routine
  container is measured only for the connector's *read* tools. The step must therefore report both
  outcomes by name rather than assume the retry succeeds.
- Do not make the retry a script. The rule that a script cannot call an MCP tool is what created
  this ticket; a wrapper that shells out to one would be the same gap with more moving parts.

## Final Report

Development completed as planned.

`rules/shell.md`'s bounds were read in full and written down before anything moved, then restated
at the route without widening: **one named tool** (`mcp__github__merge_pull_request`), **one named
precondition** (`merge_reason == session_type_cannot_merge`), **one act** — reads, writes and
pull-request creation stay REST, and every other rung (`merge_not_allowed`, `head_moved`,
`merge_forbidden`, `merge_failed`) is reported as-is and never retried, because each names a
conflict, a race, a permission or an unclassified failure and none of those is fixed by a
different transport.

The retry is now three numbered steps of the `review` route — precondition, one attempt through
one tool, and the retry's own reported outcome — with the closing rule stated in both contract
documents and in `CLAUDE.md`'s `/implement` row: **a run that reports
`session_type_cannot_merge` and no retry outcome is non-conformant on its face.** That is the
whole enforcement, deliberately, and it is the Open-Decision contract's shape for a prose rule no
script can enforce.

### Discovered Insights

- **Insight**: The enforcement had to stay prose, and the test had to prove the bounds rather
  than the behaviour.
  **Context**: The gap exists precisely because a script cannot call an MCP tool, so any
  mechanical enforcement would be a wrapper shelling out to one — the same gap with more moving
  parts, which the ticket's Considerations name. What a test *can* do is pin that the route
  states the precondition, the one-attempt bound, the one tool and the non-conformance rule, and
  that `rules/shell.md` still authorizes exactly those — so widening the permission at the route
  while the rule says otherwise now fails.

- **Insight**: The "no script gained an MCP call" gate did not exist and is worth more than the
  wording pins.
  **Context**: The suite already bans `gh issue|pr|repo` under `skills/` and `hooks/`; nothing
  banned `mcp__`. A new check walks every shipped script and asserts none references an MCP tool
  outside a comment. It passes today with the allowlist empty, which is the point: the one place
  the connector may be reached is the agent's step, and a script quietly acquiring one is exactly
  the drift this mission's ticket warned about.
