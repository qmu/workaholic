---
created_at: 2026-08-31T20:29:34+00:00
status: done
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

## Final Report

Development completed as planned, with one deliberate departure from step 1 that the ticket's own
Considerations already called for: **the assertions were added to `verify-base-health` rather than
to a new `verify-*` arm.** That drill already seeds exactly the fixture this behaviour needs — a
bare origin, a five-commit base and a per-commit `gh` stub answering out of a fixture directory —
and "reuse whatever seeder the first ticket's reproduction built rather than writing a second one"
is what the ticket asks for. A second arm would have been a second seeder for one mechanism, and
the register's own rule (one drill, one breaker, one mission) reads worse split in two.

What the drive found already present, and verified rather than rewrote:

- `base_health_walks_past_a_checkless_tip` — a tip nothing ran on resolves to the newest checked
  ancestor, and the verdict names that commit (`checked_at` == `last_green`, != `tip`) and its
  distance (`checked_behind: 2`).
- `base_health_only_no_checks_is_walked_past` — an unanswerable that is a fact about **us** stays
  terminal and names no checked ancestor.
- The two controls the ticket names are the drill's existing rows: a checked tip
  (`base_health_reads_green` / `_reads_red_with_names`) and the bound
  (`base_health_unattributable_tail`).

What this drive wrote:

- The blame table in `docs/loop-drill-runbook.md` gained a row per new assertion — the
  failure-reason to file mapping step 5 asks for, each written against the behaviour and naming
  the measured failure it guards.
- The runbook's operator-procedure line and the drill's own `WHAT IT PROVES` header now name the
  bookkeeping tip, so the drill's coverage is legible before reading its body.
- No matrix leg was added, and none was needed: `loop-drills.yml` derives its matrix from
  `verify-all --list --kind hermetic`, and `verify-base-health` is already in it as `hermetic`
  with `Breaker: yes`.

### Discovered Insights

- **Insight**: The register's breaker column is a fact about the drill, not about each assertion.
  **Context**: Adding load rows to a drill that already carries a breaker keeps it `proved`; a
  reverted walk turns the two new load rows red and fails the drill just the same, which is the
  ticket's "reverting the walk change turns the drill red" criterion without a second breaker.
