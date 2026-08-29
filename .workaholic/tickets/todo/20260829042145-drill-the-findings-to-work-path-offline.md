---
created_at: 2026-08-29T04:21:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-s-own-findings-become-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Drill the findings-to-work path offline

## Overview

PROPOSED. `sh scripts/e2e/loop-drill.sh verify-findings-to-work` — the whole path in one
offline run: **finding → classification → brake → filing → suppression**, over a
tick-log fixture with the transport stubbed and **no network**, so the mission's claims
are facts a change can lose rather than prose a reader has to trust.

It carries a **breaker row** that fires the moment the classification widens to *every*
finding — the mission's one safety property, and the one a refactor is most likely to
lose while keeping every output shape intact. Written against the **behaviour** (a
`needs_ruling` finding reaching the filer) rather than against a return shape, on
`verify-checkin-delivery`'s own lesson: a breaker written against the shape passes a
refactor that keeps the shape and loses the bound.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/qa-ownership.md` — the change ships with the drill that proves it

## Key Files

- `scripts/e2e/loop-drill.sh` — the new `verify-findings-to-work` target beside the
  existing ones; read `verify-checkin-delivery` and `verify-rulings` first, which are the
  two closest in shape (a tick-log fixture, and a stubbed `gh` with a bare local origin).
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason → file
  blame table; this target's rows go here.
- `CLAUDE.md` — the drill enumeration in the Routines section names every target; add
  this one **in the same commit** (an outdated document is a defect by this repo's rule).
- `plugins/workaholic/skills/moderate/scripts/step-file-findings.sh` and the three
  readers tickets 4–6 add — the subjects under drill.

## Implementation Steps

1. Read `verify-rulings` end to end: it stubs `gh`, uses a bare local origin, and its
   breaker is in **two halves**, each proved able to fail. That structure is the target.
2. Build the fixture: a tick log carrying at least one `repairable` finding and one
   `needs_ruling` finding, so the split is exercised in a single run rather than asserted.
3. Assert, in order — the classification names each finding correctly; the brake holds a
   second candidate while one issue is open and releases when it is closed; an unreadable
   brake files nothing and says so; the filing goes through `file-inbound-ask.sh` with the
   direction line from `ask-feedback-line.sh`; a second tick files nothing (the structural
   dedup); the filed subject's question is held while the unfiled one still asks; and the
   run report names filed, held and left distinctly.
4. Assert the negative space too: **no network call**, nothing written into the tree
   beyond the tick log, no branch, no pull request, no merge, no claim touched.
5. Add the breaker row — the classification wired to call every finding `repairable` —
   and **prove it fails** before landing. A breaker nobody has seen fail is not a breaker.
6. Update `docs/loop-drill-runbook.md` and `CLAUDE.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-findings-to-work` passes with no network and no `gh`.
- Every row of step 3 is asserted, and the breaker row was observed to fail.
- The runbook and `CLAUDE.md` name the target.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-findings-to-work`
- The same command with the breaker wired in, which must fail.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The drill is green, the breaker was shown red, and both documents are updated.

## Considerations

- The drill assumes the server's full `gh` and `qfs` like every other target in that
  script — it is operator tooling outside the plugin and ships to no other agent. Keep it
  that way rather than moving any of it into `test-workflow-scripts.mjs`, whose contract
  is hermetic and script-only.
- If a row cannot be asserted offline, say which and why in the runbook rather than
  quietly dropping it or reaching for the network.
