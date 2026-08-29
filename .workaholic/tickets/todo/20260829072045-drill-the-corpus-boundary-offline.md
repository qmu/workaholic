---
created_at: 2026-08-29T07:20:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-closing-link-readable-as-the-corpus-grows
merge_policy:
verification_handoff: 
---

# Drill the corpus boundary offline

## Overview

PROPOSED. Add a `loop-drill.sh` row that walks survey → residue → question over a corpus
past the batching boundary with no network, plus a **breaker** row that fires the moment the
batching tolerance is removed — written against the **behaviour**, not the return shape, so
a refactor that keeps the shape and loses the tolerance still fires it. The suite pins the
unit; the drill pins the chain the operator actually depends on.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-gaps.md` — the property is drillable on demand, not waited for

## Key Files

- `scripts/e2e/loop-drill.sh` — the new row, beside `verify-residue`, `verify-arrival` and
  `verify-propose`, whose fixture-building patterns it should follow.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason → file blame
  table, which the new row must be added to.
- `CLAUDE.md` — the drill-row enumeration.

## Implementation Steps

1. Build the fixture as the neighbouring rows do: a git-backed throwaway repository, no
   network, no `gh`, with a corpus whose **path list** exceeds one `xargs` batch — the filler
   count derived from the boundary rather than hard-coded.
2. Walk the chain end to end: `attributed-work.sh` attributes the citing artifacts at both
   hops → `survey-strategies.sh` produces an unrefused row with real `waiting_*` → the residue
   does not name the citing mission → `/moderate`'s `direction-arrived` question is not asked
   about work the tree attributes.
3. Assert the degraded direction too: a walk that could not read reports its reason, refuses
   the row, and produces no residue list and no question.
4. **Write the breaker against behaviour.** Restore the truncating `||` on one hop and the row
   must fail — not because a field is missing, but because a citation the fixture places in an
   early batch is no longer attributed. A breaker keyed on the return shape passes a refactor
   that reintroduces the bug, which is the failure mode this row exists to catch.
5. Prove the breaker can fail before trusting it, as the other rows' notes require, and label
   it as the intentional failure.
6. Register the row in `docs/loop-drill-runbook.md` and in `CLAUDE.md`'s enumeration, in the
   same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A new `loop-drill.sh` row walks survey → residue → question over a corpus past the boundary
  and passes with no network and no `gh`.
- The row covers the degraded direction as well as the healthy one.
- The breaker row fires when the batching tolerance is removed from either hop, and is proved
  able to fail.
- The runbook and `CLAUDE.md` name the row in the same commit.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh <new-row>` — green.
- The same row with the tolerance reverted on hop 1, then on hop 2 — red both times.
- `git status --porcelain` after the run is empty; no fixture escapes the temp dir.

**Gate** — what must pass before approval:

- The row makes no network call and needs no credential.
- Every other drill row still passes.

## Considerations

- `loop-drill.sh` is operator tooling outside the plugin and assumes the server's full `gh` and
  `qfs`; this row must nonetheless need neither, like `verify-propose` and `verify-residue`.
- Building a corpus past the boundary costs wall-clock in fixture setup. Keep the file bodies
  minimal — what must be large is the path list — and state the boundary derivation in a comment
  so a later reader does not "optimise" the row into proving nothing.
