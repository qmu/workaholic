---
created_at: 2026-08-28T21:20:22+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: put-the-loop-s-standing-rulings-on-one-pull-request
merge_policy:
verification_handoff: 
---

# Drill the ruling path with no network

## Overview

PROPOSED. Make the whole path provable on demand rather than by waiting for a tick, with
a breaker row that fires the moment a script judges on its own or the seam merges a
ruling — the two bounds this mission's safety rests on.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — gains `verify-rulings`
- `docs/loop-drill-runbook.md` — the verb, its fixture and its failure-reason→file blame
  row, in the same commit
- `CLAUDE.md` — the drill list names the new verb

## Implementation Steps

1. Add `verify-rulings` over a **git-backed** fixture holding exactly one unattributed
   active mission and one unmapped address, with the REST transport **stubbed** and **no
   network at any point**.
2. Assert the pull request **lands and does not auto-merge** — `merge_reason:
   ruling_touching` with `WORKAHOLIC_AUTO_MERGE=1` set, so the seam's refusal is what is
   proved rather than a caller's omission.
3. Assert a **second tick is a byte-identical no-op**: nothing drafted while the first
   ruling pull request is open, and no second line in `.claude/git-identities`.
4. Assert **every refusal leaves the tree untouched** — each of `carry-attribution.sh`'s
   five refusals, and an unwritable mapping.
5. Assert an **undecidable subject still draws its question**, naming why it could not be
   judged.
6. Carry a **breaker row** that fires the moment a script judges an Aim on its own, or the
   seam merges a ruling — written against the behaviour rather than the output shape, so a
   refactor that keeps the shape and loses the bound still fires it.
7. Follow the runbook's existing verb conventions: exit codes, fixture teardown, and the
   blame table.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-rulings` passes with no network and no `gh`.
- The breaker row fails when either bound is removed.
- The drill tears its fixture down and leaves the checkout byte-identical.
- The runbook and `CLAUDE.md` name the verb in the same commit.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-rulings`
- The same run with each bound deliberately removed, asserting failure.

**Gate** — what must pass before approval:

- `git status` clean after the drill.

## Considerations

- A drill that only asserts the happy path would pass over a seam that merged the ruling,
  which is the one failure this mission cannot tolerate. The breaker is therefore the point
  of the ticket, not an addition to it.

## Final Report

Development completed as planned.

`sh scripts/e2e/loop-drill.sh verify-rulings` walks the whole path over a bare local origin
with `gh` stubbed and **no network at any point**: the set read with its evidence and repair
and nothing judged, a judged set landing as one pull request the seam refuses to merge with
`WORKAHOLIC_AUTO_MERGE=1` deliberately set, a second tick that is a no-op while that ruling is
open (and the base's mapping gaining no second line), a subject the ruling does not name still
asking and saying **why**, a subject it does name held and counted, all five of
`carry-attribution.sh`'s refusals leaving the tree byte-identical, and an absent mapping
refused as a bootstrap repair. Ten load-bearing rows, exit 0, checkout byte-identical after.
The runbook and `CLAUDE.md` name the verb in the same commit.

**Both halves of the breaker were run deliberately broken and both fired**:
`rulings_seam_never_merges` turns red when `publish-tree-pr.sh`'s `ruling_touching` gate is
removed (the ruling merges, `merged: true`), and `rulings_no_script_judges` turns red when the
reader is made to resolve the single active strategy on its own.

### Discovered Insights

- **Insight**: the breaker had to be written against the **behaviour**, not the output shape.
  The fixture carries exactly one active direction beside exactly one unattributed mission
  precisely because that is the shape an inference resolves without being asked; a text-based
  pin would pass over any refactor that spelled the inference differently.
  **Context**: the second half needs the variable *set*, for the mirror-image reason — an
  unset `WORKAHOLIC_AUTO_MERGE` would let the seam's refusal be deleted unnoticed.
- **Insight**: `immutable_field` is the one `carry-attribution.sh` refusal with no natural
  fixture; a mission file with **no frontmatter at all** reaches it, because the candidate awk
  exits non-zero on a first line that is not `---`.
  **Context**: any later drill of that writer meets the same gap.
