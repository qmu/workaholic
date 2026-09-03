---
created_at: 2026-09-03T09:02:50+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-red-base-impossible-for-the-loop-to-miss
merge_policy:
verification_handoff: 
---

# Require a verdict per declared suite on the tip

## Overview

`read-base-checks.sh` answers the base's colour from the newest verdict the base carries, so a
suite that never ran on the offending commit is indistinguishable from one that passed. Measured:
a path-filtered workflow did not fire on a commit that broke the suite it guards, the newest
verdict on that commit was a different, green one, and the base read green for about an hour while
the loop merged into it. The declared workflows are already a list; this ticket makes the reader
require one verdict per declared suite on the tip and answer `unverified: <suite>` for a suite
with no run there.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/read-base-checks.sh` — the one reader of the base's checks
- `plugins/workaholic/skills/moderate/scripts/attribute-base-red.sh` — its consumer for the red attribution walk
- `.github/workflows/` — the declared suites the reading is taken against
- `plugins/workaholic/skills/drive/reference/claims.md` — the base's own checks vocabulary table, keyed on the words this reader emits
- `scripts/test-workflow-scripts.mjs` — the suite that fails on an unclassified word

## Implementation Steps

1. **Reproduce and localize first.** Run `read-base-checks.sh` against a commit whose declared
   workflows did not all fire and record what it answers today; confirm the missing verdict is
   reported as green rather than as absent, and name the line that does it.
2. Establish where the declared set comes from — the workflow files present on the tip — and
   whether any is legitimately conditional, so a suite that *cannot* run on a commit is not
   reported as unverified forever.
3. Add `unverified: <suite>` as its own answer, never folded into green and never into red: a
   suite that did not run is an absence of a reading, which the claims vocabulary already
   classifies as a judgement rather than a proof.
4. Register the new word in `drive/reference/claims.md`'s base-checks sub-table with its consumers,
   so the suite's unclassified-word assertion passes.
5. Leave the walk-past-a-`no_checks`-tip behaviour and every other `unanswerable` case untouched.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `read-base-checks.sh` answers `unverified: <suite>` for a declared suite with no run on the tip
- The word is neither green nor red and is registered in the base-checks vocabulary with its consumers
- Every existing answer (`green`, `red`, `unanswerable`, the walked-past `no_checks` tip) is byte-identical

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` including the vocabulary rows
- A hermetic case over a commit with a declared suite that did not run

**Gate** — what must pass before approval:

- The suite passes and no consumer reads `unverified` as green

## Considerations

- The ask's proposed mechanism — a verdict per declared suite — is the reporter's hypothesis and is
  recorded as such; step 1 establishes the current classification before it is adopted.
- A conditional workflow that legitimately never fires on most commits would otherwise report
  unverified forever; step 2 exists so that case is decided rather than discovered later.
- This ticket changes the reader only. The surfaces that report the colour are the sibling ticket's.
