---
created_at: 2026-08-30T04:20:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: draft-a-dateless-direction-with-the-operator-s-one-week-default
merge_policy:
verification_handoff: 
---

# Pin the dateless-ask chain hermetically

## Overview

PROPOSED. Everything this mission changes is **prose plus one small script**: the
bar in `SKILL.md`, the composition in `workflow.md`, the wording on three surfaces.
Prose regresses silently — the measured failure this mission answers was itself a
correct rule producing a silent outcome — so the chain gets the same treatment every
other load-bearing prose contract in this repository has: a hermetic pin, and a
breaker row written against the **behaviour** rather than a return shape.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the existing
  ask → reader → scaffold → floor chain test is the shape to follow
- `scripts/e2e/loop-drill.sh` — the drill dispatcher, if a drill row is the better
  home for the end-to-end walk
- `docs/loop-drill-runbook.md` §9 — the drill register; a new drill must be
  classified there or it reads `skipped:unclassified`
- `plugins/workaholic/skills/strategy/scripts/default-target-date.sh` — under test

## Implementation Steps

1. Pin `default-target-date.sh` directly: seven days from a given basis, the basis
   reported, and `bad_ask_date` on a malformed argument with no date emitted.
2. Pin the **bar**: an ask with an aim and an owner and no date resolves to the
   default; an ask stating a resolvable date resolves to that date and the default
   is never consulted; an ask stating an unresolvable one stays `no_target_date`.
3. Pin the **visibility**: the composed `## Schedule` names the default, and a
   stated-date strategy's prose does not.
4. Pin what must **not** move: `create.sh` byte-identical, no strategy frontmatter
   key added, `publish-tree-pr.sh` still deriving `strategy_touching` from the path
   so a defaulted strategy is left open by the same mechanism.
5. Carry a **breaker** row: wire the default so it also fires when the ask *stated*
   a date. The suite must go red on it — a pin that cannot fail proves nothing.
6. If this lands as a drill rather than a suite row, register it in
   `docs/loop-drill-runbook.md` §9 with its hermetic classification, so `verify-all`
   runs it and CI names it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each of the three bar outcomes is asserted, and the visibility wording with them
- The breaker is proved to fail on the deliberately mis-wired default
- No network call, no `gh`, no Slack post, and nothing written outside the fixture

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all` — the new row classified and running
- The breaker run, shown red, then reverted

**Gate** — what must pass before approval:

- The suite passes on the unmodified tree and fails with the breaker applied

## Considerations

- Prefer a row in the existing hermetic suite over a new drill if the whole chain is
  reachable without a fixture repository: the suite runs on every push already, and a
  new drill costs a register row and a matrix leg. Decide from what the assertion
  actually needs to touch, and say which was chosen.
- The date is a **clock-dependent** value, so assert it relative to a supplied basis
  rather than to today — a test that computes "a week from now" on both sides proves
  nothing about the arithmetic.
