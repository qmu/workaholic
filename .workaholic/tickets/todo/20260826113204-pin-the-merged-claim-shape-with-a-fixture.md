---
created_at: 2026-08-26T11:32:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: tell-a-merged-claim-from-a-live-one-at-both-grains
merge_policy:
verification_handoff: 
---

# Pin the merged-claim shape with a fixture

## Overview

PROPOSED. Ticket 1 of 8, and the one that retires "a shape nothing has measured".
`claims_superseded`'s own header gives that as the reason mission claims were left out of
scope; the shape has since been measured on this repository, and this ticket turns that
evidence into something that fails when the behaviour regresses. Every ticket below is
proved against this fixture.

Build a throwaway repository in the smoke-test harness carrying a squash-merged **mission**
claim and a squash-merged **batch** claim, and assert what today's oracle answers for each.
Assert the current behaviour, not the intended one — this ticket is the baseline, and
ticket 4 is what changes the answer.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic harness. It builds throwaway
  repositories under the OS temp dir, never touches the working tree, and never calls
  `gh` or the network; the fixture goes here and inherits all three properties.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — READ, especially
  `claims_superseded` and `claims_scan`. The fixture must reproduce the real input shape:
  a pushed claim branch, a `Claim <unit-id>` commit, and the artifacts the claim stamps.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the oracle the fixture runs.

## Implementation Steps

1. Read `claims_superseded` and `claims_scan` whole. The fixture is only worth anything
   if it feeds them the shape they actually consume — the artifact list, the base ref,
   and the claim branch — so read before building.
2. Build the fixture repository: a base branch, a claim branch with a `Claim` commit, and
   a **squash** merge of that branch into the base so no branch commit is reachable from
   it. That non-reachability is the whole point; a normal merge would not reproduce it.
3. Create two claims in it: one **mission** unit (stamping only `mission.md`) and one
   **batch** unit (stamping tickets that are archived on the base).
4. Assert today's answers: the batch claim reads `superseded`, the mission claim does not,
   and the mission claim reads resumable. Write the assertions so their messages name
   which grain failed.
5. Keep it offline: no `gh`, no network, no touching the working tree.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The fixture reproduces a squash-merged claim: `git rev-list --count base..ref` is
  greater than zero while the content is on the base.
- The suite asserts today's answer for both grains and passes on the unchanged tree.
- No network call and no `gh` invocation is added.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `git status --porcelain` is clean after the run.

**Gate** — what must pass before approval:

- The suite passes before any behaviour change, which is what makes it a baseline.

## Considerations

- Asserting the *current* answer feels backwards and is deliberate: without it, ticket 4's
  change cannot be shown to have changed anything, and a later regression has nothing to
  fail against.
