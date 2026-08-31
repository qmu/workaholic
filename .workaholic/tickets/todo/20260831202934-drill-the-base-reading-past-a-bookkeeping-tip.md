---
created_at: 2026-08-31T20:29:34+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-the-base-s-colour-past-a-bookkeeping-tip
merge_policy:
verification_handoff: 
---

# Drill the base reading past a bookkeeping tip

## Overview

PROPOSED. The measured failure was silent for a full day and looked exactly like a healthy
quiet step, which is the property that makes it worth a drill rather than a test alone: a
regression here produces no output to notice. The drill turns it into a check run named after
the behaviour, which is what lets `/moderate`'s `drill-health` step name it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; `verify-all` derives its set from the `case`
  arms plus the register.
- `docs/loop-drill-runbook.md` §9 — the drill register, one table and one reader.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader.

## Implementation Steps

1. Add one `verify-*` arm seeding a base with a `no_checks` tip over a checked ancestor, plus
   the two control cases: a checked tip, and a tip whose reading failed for our own reasons.
   Stub the check reader so the drill needs no credential and makes no network call.
2. Assert the **behaviour**: the bookkeeping tip yields a colour and its distance; the
   own-failure tip stays terminal and named; a walk that exhausts its bound says so rather
   than guessing.
3. Register it in `docs/loop-drill-runbook.md` §9 with a `bearing: "breaker"` row written
   against that behaviour — a drill with no breaker row is `unproved` and counted outside the
   passing total, and an unclassified drill fails the suite.
4. Add its matrix leg to `.github/workflows/loop-drills.yml`, hermetic: no credential, no
   permission beyond the default read.
5. Add the failure-reason to file blame row the runbook's tables carry.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-all` runs the new drill and reports it in the drill
  vocabulary (`pass` / `fail` / `skipped:<reason>`).
- Reverting the walk change turns the drill red; restoring it turns the drill green.
- The drill runs offline with no credential.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The register row is a breaker written against the behaviour, not against a return shape.

## Considerations

- Seeding check runs offline means stubbing the reader rather than calling GitHub. Say so in
  the runbook row: the drill proves the **walk**, not that any real repository's CI reports
  check runs, and the reader's own limit (check runs only, never legacy commit statuses) is
  untouched by this mission and stays stated where it already is.
- Reuse whatever seeder the first ticket's reproduction built rather than writing a second one.
