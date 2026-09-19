---
created_at: 2026-09-19T19:30:00+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
---

# Reconcile the P8 maintenance registry with the steps it ships

## Overview

`node --test scripts/tests/agentic-loop/*.test.mjs` fails on `main` at
`P8 maintenance registry is ordered and complete`
(`scripts/tests/agentic-loop/delivery-report.test.mjs:87`). The moderation tick now ships two
steps the test's expected list does not carry — `unattributed-asks` and `propose-yield`, both
sitting between `blocked-tick` and `inbound-sweep` — so the registry the test pins and the
registry the tick runs disagree by two rows.

Observed 2026-09-19 at `d28e34429` from the untouched main checkout, so it predates and is
independent of the unit that recorded it (mission
`stop-the-codex-clock-dying-silently-and-writing-the-locks-it-reads`). `read-base-checks.sh`
reads the base `red` with `validate` failing on the same tip, which is consistent with this
being the failing row.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a pinned contract that drifts from what
  ships stops being a contract

## Key Files

- `scripts/tests/agentic-loop/delivery-report.test.mjs` — the `P8 maintenance registry` row and
  its expected ordered list.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the numbered step list the tick
  actually runs, and the ordering the registry is meant to mirror.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the runner that enumerates the steps.

## Implementation Steps

1. Establish which side is wrong before changing either. Read the shipped step order from the
   runner and the workflow reference, and confirm that `unattributed-asks` and `propose-yield`
   belong where they now sit rather than the test's list being the intended order.
2. If the steps are correctly placed, extend the expected list in the test with both rows, in the
   shipped order, and keep the assertion `deepStrictEqual` — an order-insensitive comparison would
   drop the ordering half of what the row is named for.
3. If either step is misplaced, move it in the runner and the reference in the same change and
   leave the test's order as the statement of intent.
4. Re-run the whole agentic-loop test set and confirm the base's `validate` check goes green on
   the next merge.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `node --test scripts/tests/agentic-loop/*.test.mjs` reports `fail 0`.
- The registry the test pins and the step order `run.sh` runs are the same list, in the same
  order.

**Verification method** — the commands/tests/probes that prove them:

- `node --test scripts/tests/agentic-loop/*.test.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- Both commands pass and the base's `validate` workflow is green on the merge commit.

## Considerations

- Two steps were added without the registry moving with them, so whatever repair is taken should
  leave the two lists derived from one source or pinned in one place, rather than adding a third
  copy of the order.
