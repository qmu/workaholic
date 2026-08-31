---
created_at: 2026-08-31T20:09:59+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-tick-s-questions-readable-and-close-them-in-the-thread
merge_policy:
verification_handoff: 
---

# Drill the outcome reply offline

## Overview

Prove the loop's own return path offline, as every other mechanism here is proved: ask →
answer → record → file → land → reply, with no network and no Slack post, and a breaker row
written against the **behaviour** so a refactor that keeps the return shape and loses the
bound still fires it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; the new `verify-answer-outcome` arm (or the
  widened `verify-return-path` rows, if that drill already stages the fixture this needs).
- `docs/loop-drill-runbook.md` §9 — the drill register; an unregistered drill is
  `skipped:unclassified` and the suite fails on it.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so the red check run is
  named after the drill.

## Implementation Steps

1. Stage a fixture: a tick log carrying an asked question with a recorded coordinate, a
   person's answer recorded against it, and a filed issue — with `gh` stubbed so the
   issue's state is the fixture's, never the network's.
2. Assert the settled path: the reply is composed once, for the right question, carrying
   the recorded answer and the outcome.
3. Assert the bounds: a `pending` outcome posts nothing; an `unreadable` one posts nothing
   and is named; a second tick posts nothing; a coordinate-less question is named rather
   than searched for; no key, cap or hold moved.
4. Assert the negative space: nothing merges, closes, re-asks, confirms or gates.
5. Add the breaker row — wire the candidate set at the answer's **existence** rather than
   at its outcome, and require that row to fail.
6. Register the drill in `docs/loop-drill-runbook.md` §9 with its `bearing: "breaker"` row,
   so `verify-all` and CI both run it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The drill runs with no network, no `gh` call that leaves the machine, and no Slack post.
- It fails when the outcome gate is removed, and passes on the unmodified tree.
- It is registered, so `verify-all` runs it and CI names it when it goes red.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-answer-outcome`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The breaker row is proved able to fail, by running it against the deliberately broken
  seam, not asserted.

## Considerations

- A drill with no breaker row is `unproved` and counted outside the passing total: the row
  is the point, not the arm.
- If `verify-return-path`'s fixture already reaches recording and filing, widen it rather
  than staging a second, near-identical repository — one fixture, two questions.
