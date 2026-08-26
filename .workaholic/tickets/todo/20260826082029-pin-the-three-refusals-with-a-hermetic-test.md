---
created_at: 2026-08-26T08:20:29+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Pin the three refusals with a hermetic test

## Overview

The three refusals are the reason this mission is admissible, and prose has not held
them: the two-writers rule on the strategy artifact has been re-decided three times. Pin
them mechanically in `scripts/test-workflow-scripts.mjs`.

Assert that `direction-health` writes nothing under `.workaholic/strategies/`, never
calls `close.sh` or `open-proposal.sh`, never lifts a `/propose` gate, and that the
strategy artifact still has exactly two writers (`create.sh` creates, `close.sh` ends). A
test is what stops a fourth re-decision.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; it builds throwaway
  repositories under the OS temp dir, never touches the working tree, and never calls
  `gh` or the network.
- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the subject.
- `plugins/workaholic/skills/strategy/scripts/` — the writer set the test counts.

## Implementation Steps

1. Read the existing suite's shape, in particular the tests that assert a script writes
   nothing and the `gh issue|pr|repo` grep whose allowlist is empty on purpose — both are
   the pattern this test follows.
2. Seed a throwaway repository with one `active` strategy whose `target_date` has passed
   and one with nothing answering it, run the step, and assert the tree under
   `.workaholic/strategies/` is byte-identical before and after.
3. Assert by inspection of the step's own closure that it names neither `close.sh` nor
   `open-proposal.sh` — a grep over the step and anything it invokes, with no allowlist.
4. Assert the writer count: exactly two scripts under `strategy/scripts/` write the
   strategy file, and `direction-state.sh` is not one of them.
5. Assert the survey's gates are untouched by running `survey-strategies.sh` before and
   after the step and comparing `refusal`, `selected` and `eligible` slugs.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The suite fails if the step writes anywhere under `.workaholic/strategies/`
- The suite fails if the step's closure reaches `close.sh` or `open-proposal.sh`
- The suite fails if a third writer of the strategy artifact appears
- The suite fails if running the step changes any `/propose` gate outcome

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Deliberately break each of the four assertions in a scratch copy and confirm each one
  fails — a test that cannot fail proves nothing

**Gate** — what must pass before approval:

- The test is hermetic: no network, no `gh`, no write to the working tree
- The documentation this change makes wrong is updated in the same commit

## Considerations

- Counting writers by grep is approximate; a writer reached indirectly would pass. The
  bound should be stated in the test's own comment rather than implied, in the same spirit
  as `attributed-work.sh` stating that its attribution is lossy.
- Step 5's before/after comparison is the weakest assertion, because the step is a pure
  read and could pass it trivially. It is kept because the failure it guards against —
  a future edit that lets a reading lift a gate — is the one the ask names by name.
