---
created_at: 2026-08-26T11:32:04+00:00
status: done
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

## Final Report

Development completed as planned. `testMergedClaimShapeAtBothGrains`, with its
`makeSquashMergedClaims` builder, is the mission's baseline: it reproduces a squash-merged
mission claim and a squash-merged batch claim in the hermetic harness and asserts what today's
oracle answers for each.

**The premise is asserted before the verdicts.** The fixture first proves that both branches
are still ahead of the base by commit count while the batch's tickets are on the base under its
archive directory — otherwise a later `git merge --squash` behaviour change could quietly turn
this into a test of nothing.

**Two assertions are written to flip.** `mission grain: a squash-merged mission claim does NOT
read superseded today` and `mission grain: and it is offered as resumable today` are today's
answer, not the intended one, and ticket 4 is what changes them. The messages name the grain so
a failure says which half moved.

**Two mechanical details the fixture had to get right**, both discovered by reading
`claims_scan` before building it: the tips are moved past the heartbeat window with a backdated
empty commit, because otherwise both claims stop at `claim_active` and never reach the gates
this fixture is about; and the squash has to be a squash, because a normal merge takes
`base..ref` to zero and `claims_scan` drops the branch before any verdict exists.

### Discovered Insights

- **Insight**: The ordering inside `claims_scan`'s verdict chain is what the fixture has to
  navigate, not just the individual predicates: `claim_active` short-circuits before
  `superseded`, which short-circuits before the drained fork.
  **Context**: Any future fixture about a late-chain verdict must age the claim tip first. The
  ordering is deliberate (liveness gates a takeover), so the right move is to age the fixture,
  never to reorder the chain.
- **Insight**: A mission claim in this harness reads `heartbeat_lapsed` rather than
  `queue_drained`, because `claims_has_work` answers `true` for a mission whose slug still
  matches a queued ticket on the branch — `seedMissionTicket` gives `m1` exactly one.
  **Context**: That is why the baseline asserts `resumable: true` rather than a specific reason
  for the mission grain: the reason depends on the mission's queue, while resumability is the
  property the measured failure was about.
