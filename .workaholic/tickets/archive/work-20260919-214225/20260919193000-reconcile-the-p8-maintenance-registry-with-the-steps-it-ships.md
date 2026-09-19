---
created_at: 2026-09-19T19:30:00+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
claim: work-20260919-214225
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

## Final Report

Development completed as planned, with one finding the ticket did not anticipate: by the time
this unit was claimed the *symptom* had already been repaired on the base by PR #1246, which
added `unattributed-asks` and `propose-yield` to `EXPECTED_STEPS`. That is implementation step 2
of this ticket and it is exactly the repair the Considerations forbid — a third copy of the order,
which goes red again on the next pull request that adds a step while another is in flight. The
suite was green on claim (163/163) and the work taken here is the Considerations' half: removing
the copy.

`run.sh` derives its step list from `steps.json` (`jq -r '.steps[].id'`), so there was never a
second *runtime* ordering to reconcile — the two lists that disagreed were the registry and the
literal `EXPECTED_STEPS` in the test. `reference/workflow.md`'s section numbering is authoring
order, not run order, and says so.

`EXPECTED_STEPS` is gone. The row now derives both halves of its own name:

- **complete** — the registry's `script` values against the `step-*.sh` files that ship, compared
  both directions, plus `script == "step-<id>.sh"` per row. Strictly stronger than the literal
  list, which never checked that a script existed at all, and it needs no edit when a step is
  added.
- **ordered** — only the orderings `reference/workflow.md` states, each with its own assertion
  message: `open-log` first, `human-checkin` last, `file-findings` after the steps whose reports
  it files, `direction-health` immediately after `strategy-pace`, `date-will-not-hold`
  immediately after `direction-health`.

Per-step identity stays pinned where each step's own change lives — `test-workflow-scripts.mjs`
already carries a `moderateSteps().includes('<id>')` row for `unattributed-asks` and
`propose-yield` — so a registry change is still stated by the pull request that makes it.

### Verification

- `node --test scripts/tests/agentic-loop/*.test.mjs` — 163 tests, `fail 0`.
- `node scripts/test-workflow-scripts.mjs` — 7814 passed, 0 failed.
- `node scripts/build-plugins/{build,verify,validate-metadata}.mjs` — no `outputs/` drift.
- `layout-doctor.sh` — `conforming: true`, 0 findings.
- **Five mutations, each failing with its own named message** (registry restored after each):
  a registered row whose script does not ship; a shipped script dropped from the registry;
  `direction-health` moved to the end; `strategy-pace`/`direction-health` swapped;
  `file-findings` swapped with the step before it. Without this the row could have passed
  vacuously.

### Discovered Insights

- **Insight**: a pinned *copy* of a derived list is the same defect whether it is a count or a
  list of names — the message improves, the staleness does not. `length` went red on PR #1224
  (`34 !== 33`), the by-name list went red on PR #1239, and both were correct against their own
  base and red on merge.
  **Context**: the distinguishing test is whether the assertion has a source other than the
  subject. `polling-cost.test.mjs` already had it right and says so in its own comment — it
  compares `plan-steps.sh`'s selected count to the registry because the *planner* is the subject,
  which proves a real property and stays green at any registry size. `loop-drill.sh:1326` derives
  its count for the same reason, recorded 2026-08-26.

- **Insight**: `reference/workflow.md` carried absolute positions in prose — *tenth in `run.sh`'s
  `STEPS`*, *fifteenth* — and both had gone stale, the second also asserting an adjacency
  (`unanswered-asks` immediately before `human-checkin`) that `file-findings` now sits inside.
  **Context**: the same defect class as the test pin, in documentation. Both were rewritten to
  the relation that is load-bearing, and the pinned adjacencies are now the ones the test asserts,
  so the reference and the row cannot drift apart silently.
