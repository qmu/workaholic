---
created_at: 2026-09-02T14:31:37+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy: review
verification_handoff: 
claim: work-20260902-234711
---

# Derive the suite's test list instead of listing it

## Overview

MEASURED, three ticks running. Every open unit of this loop is stuck on the same one file,
and the collision is structural rather than a disagreement between authors.

`scripts/test-workflow-scripts.mjs` registers each test twice: a `function test…()` body,
and a row in the single `const tests = [` array at line 22090. Every unit this loop drives
adds both. So **two units driven concurrently collide by construction**, at the same two
anchors, whatever they changed.

Measured 2026-09-02 by merging `origin/main` into the `batch-20260902220350` worktree and
aborting: exactly one conflicting file, exactly two hunks, and both are *disjoint appends* —
this branch's new function and row against `main`'s own new function and row. Nothing about
the two changes disagrees. `.workaholic/stories/index.md` collided too and was resolved by
the union driver already in `.gitattributes`.

The cost as it stands: three pull requests (#890, #899, #900) have been unmergeable for a
day. `conflict-class.sh` classifies the collision `content`, which is correct — it is a
hand-written file — so `catch-up-claim.sh` refuses `content_conflict` every tick and the
loop cannot deliver its own work.

**The repair is to stop registering the same test twice.** Derive the list the runner walks
from the module's own `test…` functions instead of maintaining an array beside them. That
removes one of the two anchors outright — the one every single unit touches — and it is the
anchor with no information in it, because a row is mechanically implied by its function.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testing-standards.md` — what a test row must still assert

## Key Files

- `scripts/test-workflow-scripts.mjs` — 35,829 lines, 400 rows, one `const tests = [` at
  line 22090. The array is the anchor to remove; the function bodies stay exactly as they are.
- `.gitattributes` — records why the OKF indexes take `merge=union` and, in the same header,
  why that reasoning does **not** extend to a file whose conflicts can carry a real
  disagreement. Read it before proposing union here; it argues against it.
- `plugins/workaholic/skills/ship/scripts/lib/conflict-class.sh` — the one classifier. It is
  not the defect and must not be widened to call this `mechanical`; the repair removes the
  occasion, as the index change did.
- `docs/loop-drill-runbook.md` §9 — the drill register, if a new drill is added.

## Implementation Steps

1. Read the runner at the foot of `scripts/test-workflow-scripts.mjs` — how it iterates
   `tests`, what it does with each row's label and function, and how failures are counted.
2. Replace the array with a derivation over the module's own declarations, keeping the label:
   the row's human sentence is the part a function name cannot carry, so it must survive.
   The cheapest form that keeps it is a label declared **at the function**, read back by the
   runner; pick the form that leaves the 400 existing bodies untouched apart from that line.
3. Convert all 400 rows mechanically. The order the runner walks may change; assert nothing
   depends on it (no shared state between rows) and say so in the story if it does.
4. Keep the assertion count and every row's label byte-identical in the output, so a
   reviewer can diff the run before and after and see no behavioural change.
5. Run `node scripts/test-workflow-scripts.mjs` and confirm the same total and the same
   pass set as before the change.
6. Regenerate: `node scripts/build-plugins/build.mjs`, then `verify.mjs`, then
   `validate-metadata.mjs`.
7. Update `CLAUDE.md`'s *Local Verification* section only if the invocation changed. It
   should not.

## Quality Gate

- `node scripts/test-workflow-scripts.mjs` reports the same number of rows and the same
  pass/fail set as the pre-change run, with the labels unchanged.
- The `const tests = [` array no longer exists, and adding a new test touches exactly one
  region of the file.
- `node scripts/build-plugins/verify.mjs` and `validate-metadata.mjs` pass.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

## Open Decisions

**Should new test functions also be placed by name order, or does removing the array suffice?**

Sources consulted. `.gitattributes`' own header states the rule this repository already
applies to conflict generators: a conflict that "carries no information" should be removed
at its occasion, and `union` is right only where "there is nothing for a resolution to
weigh". A test function is not that — two branches editing one function is a real
disagreement — so union is refused here on the repository's own stated grounds, and this
decision is not about union. The measurement above says the array is one of exactly two
anchors, and the only one every unit touches.

The fork. **Removing the array alone** leaves append-at-end-of-file as the remaining anchor:
two units still collide when both append there, though a resolution is then a genuine
"keep both functions" rather than a four-way one. **Placing each function by name order**
spreads new bodies across 35k lines, so two units collide only when their test names sort
adjacently — rarer, at the price of a convention nothing enforces and a reviewer's diff that
no longer shows new tests in one place.

A third side exists and is worth naming: **splitting the suite into one file per area**,
which removes the occasion entirely. It is a large restructure of this repository's central
safety net and was deliberately not chosen here.

The driving session should decide from the first two and record which, with its reason.
Whoever rules on the third should be the operator.

## Considerations

- This ticket does not resolve #890, #899 or #900. Those three still need a person to merge
  `origin/main` and keep both sides in the suite file; that judgement is reserved to a person
  by the claim protocol and an unattended run must not take it.
- Since the `catchup-blocked` step was retired, no `/moderate` surface asks anybody about a
  `content` conflict. The three stuck pull requests are named only in `/implement`'s run
  report. That is a separate gap and is not repaired here.

## Final Report

Development completed as planned. The `const tests = [` array is gone; each test is registered by a
`T("<label>", testFn);` call on the line **above** its own declaration, and the runner walks what
the file declared.

**The Open Decision is ruled: removing the array alone, not name-ordered placement.** Reason: the
measurement in this ticket says the array is the anchor *every* unit touches, while
append-at-end-of-file is one that only collides when two units append in the same window — and the
residual conflict there is a genuine "keep both functions", which a person can resolve in seconds
and which `conflict-class.sh` is right to call `content`. Name-ordered placement buys rarer
collisions at the price of a convention nothing enforces and a reviewer's diff that no longer shows
new tests together; that trade is not worth making for a residue this small. The third side —
splitting the suite into one file per area — stays the operator's, untouched.

**Two real defects surfaced during the conversion, and both are recorded in the file's own header
because either would have been silent.**

1. **Registering below the body cannot be done by scanning for the next column-0 `}`.** 115 of the
   400 bodies contain one inside a template literal (a shell snippet, a JSON fixture), so the
   insertion landed mid-body and the `T(…)` call then only ran if that test ran. Measured: 285 of
   400 registered. Registration moved **above** the declaration, which is unambiguous and works
   because a function declaration is hoisted.
2. **The runner had to move to the end of the file.** Registration now happens in file order at
   module load, and 115 tests are declared *below* where the array sat — so leaving the loop there
   ran 285 and skipped the rest, exactly the failure the file's own `await` note was written
   against: a test that does not run is worse than one that fails. The header now says anything
   appended after the runner never executes.

**Verified, not asserted**: the 400 labels are byte-identical to the array's (compared
mechanically against `HEAD`'s copy — 0 missing, 0 added), the run prints 400 sections, and
`6236 passed, 0 failed`. Order changed from array order to file order; nothing depends on it, since
every row builds its own fixture in a fresh temp dir and shares no state.

`CLAUDE.md`'s *Local Verification* section is unchanged — the invocation did not move.

**This does not resolve #890, #899 or #900**, as the ticket states: those three still need a person
to merge `origin/main` keeping both sides in the suite file.

### Discovered Insights

- **Insight**: A conversion that changes *when* code runs can silently reduce coverage, and the
  suite's own pass count is the only thing that shows it.
  **Context**: Both defects here produced a green run — 285 tests passing, 115 never executed. The
  check that caught it was comparing the section count against the array's length, which is worth
  keeping in mind for any future move of this file's structure.
- **Insight**: `^}` at column 0 is not a function boundary in this file.
  **Context**: Template literals carrying shell and JSON fixtures put unindented braces at line
  start, which defeats every line-based structural edit. Anchor on the declaration, never on the
  body's end.
