---
created_at: 2026-08-26T08:20:29+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Drill direction health with no network

## Overview

Every other part of this loop is provable on demand rather than by waiting for a tick —
`verify-specificate`, `verify-implement`, `verify-propose`, `verify-moderate`. Add
`scripts/e2e/loop-drill.sh verify-direction-health`.

Seed an overdue direction, a dormant one and an empty tree; assert each reading, each
question key, the once-only gate, and that nothing was written — with no network and no
credential, so the chain is provable by an operator in a checkout rather than by
watching a channel for an hour.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — operator tooling outside the plugin; the existing
  `verify-*` verbs are the shape to follow.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason→file
  blame table both live there and must gain this verb's rows.
- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` and
  `strategy/scripts/direction-state.sh` — the subjects.

## Implementation Steps

1. Read `verify-propose` first: it drills the real gates with no network at all, which
   is exactly the constraint here, and its seeding helpers are reusable.
2. Seed three fixtures in a throwaway tree: a strategy whose `target_date` has passed
   while carrying landed work (the case `pace` reads `on_course` and nobody is told
   about), a strategy that is live, in date and unanswered, and a tree with no `active`
   strategy at all.
3. Assert `direction-state.sh` answers `overdue`, `dormant` and `none` respectively, and
   `unreadable` when the survey is made to fail.
4. Assert the step's question keys are exactly `direction-overdue:<slug>`,
   `direction-dormant:<slug>` and `direction-none`, and that a second run of the same
   tick asks nothing further.
5. Assert the tree is byte-identical after the drill, `.workaholic/strategies/`
   included.
6. Add the verb's rows to `docs/loop-drill-runbook.md` — the procedure and the blame
   table — in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-direction-health` passes on a clean checkout
  with no network and no credential
- It asserts all four readings, all three question keys, the once-only gate and a
  byte-identical tree
- The runbook names the verb, its procedure and what each failure reason blames

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-direction-health`
- Run it with the network disabled to prove the no-network claim rather than assert it
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The drill makes no `gh` call and no network call of any kind
- The documentation this change makes wrong is updated in the same commit

## Considerations

- `survey-strategies.sh` makes one network call (the open-proposal gate) and refuses the
  tick rather than proceed without it. The drill must supply that read through
  `--open-proposals` rather than stub the transport, or it is not drilling the real path.
- The drill is operator tooling and ships to no other agent; the hermetic suite (this
  mission's previous ticket) is what CI enforces. Both exist on purpose and the split
  should be stated in the runbook rather than left to be inferred.

## Final Report

Development completed as planned.

`scripts/e2e/loop-drill.sh verify-direction-health` builds a throwaway strategy tree — one
direction past its date **while carrying landed work**, one live and unanswered — plus an empty
tree, hands the survey a synthetic open-proposal list through `--open-proposals`, and asserts
nine load-bearing rows: the four readings (`overdue`, `dormant`, `none`, `unreadable`), the three
question keys, the asked-once gate, and a byte-identical checkout with the seeded
`.workaholic/strategies/` area untouched. `docs/loop-drill-runbook.md` gains the command row, the
procedure section (5h) and the blame table, and `CLAUDE.md`'s verb list names it.

**The no-network claim was proved, not asserted**: the whole drill was re-run under `env -i` with
`gh` absent from `PATH` and both proxies pointed at a dead port (`http://127.0.0.1:1`), and all
nine rows still passed. The drill's own closure names no `gh`, `curl` or `wget`.

### Discovered Insights

- **Insight**: the two readers in this chain emit **two different JSON formattings** — the happy
  paths come from `jq -c` (no space after the colon) and the degrade paths from shell `printf`
  (spaced) — so every matcher in the drill has to tolerate the optional space.
  **Context**: caught by two rows that failed while the behaviour underneath was correct, which
  is the worst kind of red. The same trap is documented in `render-tick-post.sh`, whose field
  patterns were widened for exactly this reason; a drill written against one producer's spacing
  breaks the first time it reads the other.
- **Insight**: "a second run of the same tick asks nothing further" cannot be drilled on the step
  — the step is stateless and re-emits its subjects every tick. The gate lives in
  `ask-question.sh`, so the drill exercises *that* with this step's key.
  **Context**: it is the right place for it: the step supplies subjects and the check-in owns the
  ledger, so a drill asserting once-only behaviour on the step would have been asserting a
  property the step deliberately does not have.
