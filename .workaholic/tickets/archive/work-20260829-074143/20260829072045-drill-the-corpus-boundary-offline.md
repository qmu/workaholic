---
created_at: 2026-08-29T07:20:45+00:00
status: done
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

## Final Report

Development completed as planned.

`sh scripts/e2e/loop-drill.sh verify-corpus-boundary` walks the chain the operator actually
depends on — survey → residue → question — over a corpus past the `xargs` batching
boundary, and the degraded direction beside it. Twelve load-bearing rows, no network, no
`gh`, no credential; the survey's one remote read is supplied through `--open-proposals`,
exactly as `verify-residue` supplies it, so the drilled path is the real one.

**The boundary is derived from the running system**: the probe counts how many times `xargs`
invokes its command over exactly the corpus the reader builds, and the filler grows until
that count exceeds one. What is large is the path list — the file bodies stay three lines —
and a comment in the row says why a hard-coded count would prove nothing.

**The breaker is in two halves, one per hop, and both are written against behaviour.** Each
runs a copy of the reader with the truncating `||` restored on one hop and requires the
citation to be *lost*: hop 1's half loses it entirely, hop 2's loses the `via_mission:`
attribution while hop 1 survives. They are separate because reverting hop 1 hides hop 2
behind it — with no attributed mission there is nothing for the second hop to walk — and hop
2 carries every ticket's attribution, so its loss is the larger one. Both were proved able
to fail before being trusted.

The row is registered in `docs/loop-drill-runbook.md` (index row plus a §5j-bis section with
the per-row blame table) and in `CLAUDE.md`'s enumeration, in this commit.

Result: `{"stage": "corpus-boundary", "verdict": "pass", "load_bearing": {"passed": 12,
"failed": 0}}`. Every neighbouring row still passes — `verify-residue` 12/12,
`verify-arrival` 16/16, `verify-propose` 15/15, `verify-expiry` 14/14,
`verify-direction-health` 11/11, `verify-rulings` 10/10, `verify-standup` 3/3 — and
`git status --porcelain` after the run is clean, which the drill asserts for itself.

### Discovered Insights

- **Insight**: the first version of the boundary probe reported **one batch over any corpus
  at all**, and the reason is `set -e`. `{ find A B; find C D; } | …` — a `find` given an
  area that does not exist yet exits non-zero, and under `set -e` that aborts the group
  **before the second `find` runs**, so the probe measured only the mission list.
  **Context**: `attributed-work.sh`'s own corpus build carries `|| :` on every `find` for
  exactly this reason; the probe now does too. It cost a ten-minute run that created 20000
  filler files and still reported one batch — and, worse, the breaker row passed while the
  probe row failed, which is what made the diagnosis obvious. Any later probe of this shape
  needs the same guard.
