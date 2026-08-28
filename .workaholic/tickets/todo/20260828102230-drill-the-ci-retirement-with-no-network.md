---
created_at: 2026-08-28T10:22:30+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: finish-a-proved-retirement-where-the-write-is-permitted
merge_policy:
verification_handoff: 
---

# Drill the CI retirement with no network

## Overview

PROPOSED. `scripts/e2e/loop-drill.sh verify-ci-retirement` — the split between the two
executors, provable on demand rather than by waiting for a workflow run.

The fixture already half exists: `verify-retire` runs over a local bare origin whose own
`update` hook refuses one ref's deletion, which is the same receive-side path a remote
refusal takes, with no network at all. This drill extends that shape to **two** actors: a
hook that refuses the container's delete and permits CI's, so the handoff is exercised
rather than asserted.

It carries a **breaker row** — a row that must fail the moment the workflow would delete a
branch that did not re-prove `superseded`. A drill with no way to fail proves nothing, and
this is the one destructive act in the loop.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the new `verify-ci-retirement` case, beside `verify-retire`
  (read that one's fixture builder and reuse its shape)
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason → file
  blame table this drill's rows must be listed in
- `.github/workflows/claim-retirement.yml` and the two scripts from earlier tickets — the
  seam under test

## Implementation Steps

1. Read `cmd_verify_retire` in full, including its bare-origin `update` hook and its
   `add_row` assertions for the blocked delete.
2. Add `cmd_verify_ci_retirement` over a fixture with a superseded claim, a live claim, and
   an origin hook that refuses the container's delete and permits the CI-side one.
3. Assert, one row each: the container reports `branch_delete_failed` and the branch
   survives; the CI-side act re-proves and deletes it; the live claim's branch is refused
   by verdict word and survives; each bound (`release/*`, open pull request, not on base,
   non-`work-*`) refuses by name; every path exits 0.
4. Assert the question's narrowing over two ticks: the CI-deletable unit is never asked
   about, the genuinely blocked one exactly once.
5. Add the **breaker row**: wire the CI-side act at the raw candidate list with the
   re-proof removed and assert the drill fails. Label it as the intentional failure, as
   every other drill here does.
6. Register the command in the usage string, the dispatch case, `docs/loop-drill-runbook.md`
   and `CLAUDE.md`'s drill enumeration.
7. No network anywhere: the transport is stubbed on `PATH` exactly as `verify-retire` stubs it.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-ci-retirement` passes with no network and no `gh`
- It proves the container's refusal, CI's success, the verdict refusal, all four bounds and
  the question's narrowing over two ticks
- It carries a breaker row that fails when the re-proof is removed
- The command is registered in the usage string, the dispatch, the runbook and `CLAUDE.md`

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-ci-retirement`
- `sh scripts/e2e/loop-drill.sh verify-retire` (must stay green)
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- All three pass, the drill leaves `git status --porcelain` unchanged, and removing the
  re-proof makes it fail

## Considerations

- The drill must leave the working tree byte-identical, as `verify-retire` does — it
  snapshots `git status --porcelain` before and after.
- A bare origin's `update` hook cannot distinguish a "CI" pusher from a container one on
  identity alone; drive the two sides by the ref or by an env the fixture controls, and say
  in the header that the distinction is the fixture's rather than GitHub's.
