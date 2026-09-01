---
created_at: 2026-08-26T11:00:16+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826110016-render-the-direction-reading-on-the-tick-root.md
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Pin the three refusals with a hermetic test

## Overview

This mission's three refusals are the part most likely to be eroded by a later reader who
sees an obvious improvement: **the loop asks, it never closes**; **no artifact gains a
field**; **`/propose`'s gates are never lifted**. A strategy carries no acceptance list and
its progress is not computed, so `achieved` can never be arithmetic the way a mission's is
— which is exactly why the temptation to close one automatically will recur.

Pin them mechanically. The two-writers rule on the strategy artifact has been re-decided
three times; a test is what stops a fourth.

## Policies

- `workaholic:implementation` / `policies/testing.md` — a rule stated in prose is a rule a change can lose
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; it already pins the
  ask → reader → scaffold → floor chain and the notification shapes, so this is a new case
  in an established shape.
- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the subject.
- `plugins/workaholic/skills/strategy/scripts/` — `create.sh` and `close.sh` are the two
  writers the third assertion counts.

## Implementation Steps

1. Read the existing chain test in `test-workflow-scripts.mjs` — it walks a real seeded
   tree rather than asserting on source text, and this case must do the same wherever it
   can, because a grep-only test passes on a rewrite that reintroduces the behaviour.
2. Assert `direction-health` writes nothing under `.workaholic/strategies/`: run the step
   over a seeded tree in every reading and compare the directory before and after.
3. Assert it never calls `close.sh` or `open-proposal.sh` — by behaviour where possible (no
   strategy changes state, no issue is opened), and by the script's own closure otherwise.
4. Assert it lifts no `/propose` gate: a strategy that is `dormant` **and** refused stays
   refused by `survey-strategies.sh` after the step has run.
5. Assert the strategy artifact still has exactly **two** writers — `create.sh` creates,
   `close.sh` ends — so a third writer added anywhere fails the suite.
6. No network, no `gh`, no credential; throwaway trees under the OS temp dir, never the
   working tree — the standing contract of this suite.
7. Name each assertion after the refusal it pins, so a failure says which rule was lost.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each of the three refusals has a named, independently-failing assertion
- A deliberately introduced third writer of the strategy artifact fails the suite
- A deliberately introduced `close.sh` call from the step fails the suite
- The suite touches no network and no working-tree file

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` passes
- Each assertion is proved to fail when the rule it pins is broken, by breaking it locally
  and observing a named failure before reverting

**Gate** — what must pass before approval:

- All four criteria hold, including the deliberate-break check for each assertion

## Considerations

- Proving a negative ("never calls X") is partly a closure read, which a rewrite can evade.
  Where an assertion is structural rather than behavioural, say so in the test's own comment
  so a later reader knows what it does and does not guarantee.

## Final Report

Development completed as planned — the assertions were already present on the base when this
ticket was driven and were verified here against its own Quality Gate rather than assumed.

`test-workflow-scripts.mjs` carries the three refusals as named, independently-failing rows:
`direction-health` writes nothing under `.workaholic/strategies/` (asserted over a seeded
tree, before and after), it calls no writer, and it lifts no `/propose` gate — a strategy
that is `dormant` and refused stays refused after the step has run. The strategy artifact's
writer count is asserted at exactly three (`create.sh`, `amend.sh`, `close.sh`); the ticket
said two, and `amend.sh` was admitted deliberately afterwards, with `carry-attribution.sh`
excluded by name because it writes on a mission rather than on the strategy.

### Discovered Insights

- **Insight**: The writer-count assertion is what forced `amend.sh` to be argued for rather
  than added — the suite failed the moment a third writer appeared.
  **Context**: This is the pin working as intended rather than an obstacle: the rule the
  ticket set out to protect has been re-decided at least once since, and the test is what
  made that a decision with a record instead of a drift.
