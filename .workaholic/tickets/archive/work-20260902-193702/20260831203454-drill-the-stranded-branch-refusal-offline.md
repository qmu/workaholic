---
created_at: 2026-08-31T20:34:54+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-a-claim-branch-is-empty-before-deleting-it
merge_policy:
verification_handoff: 
---

# Drill the stranded-branch refusal offline

## Overview

PROPOSED. This is the one mechanism in the loop whose regression destroys work rather than
delaying it, and the ask says exactly why a drill is owed: the 403 blocking the delete has been
keeping the measured branches alive by accident, so the day the transport is repaired is the
day a regression here becomes silent loss. The drill is what makes that regression a named red
check run instead.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; `verify-all` derives its set from the `case`
  arms plus the register.
- `docs/loop-drill-runbook.md` §9 — the drill register, one table and one reader.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so the red check run is named
  after the drill and `/moderate`'s `drill-health` step can name it.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader.

## Implementation Steps

1. Add one `verify-*` arm over the first ticket's reproduction, seeding all three cases: a
   branch empty against the base, a branch holding a file that is on no other ref, and a branch
   whose diff cannot be read.
2. Assert the **behaviour**, with the delete allowed to actually run in the sandbox: the empty
   branch is deleted; the branch holding work is refused and its files named; the unreadable one
   is refused. Assert at both grains, and assert that the file which would have been lost still
   exists afterwards — that is the property, and asserting a return word instead would pass over
   a delete that happened anyway.
3. Register it in `docs/loop-drill-runbook.md` §9 with a `bearing: "breaker"` row written
   against that behaviour.
4. Add its matrix leg to `.github/workflows/loop-drills.yml`, hermetic: no credential, no
   permission beyond the default read, no network.
5. Add the failure-reason to file blame row the runbook's tables carry.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-all` runs the new drill and reports it in the drill
  vocabulary (`pass` / `fail` / `skipped:<reason>`).
- Reverting the diff term turns the drill red; restoring it turns it green.
- The drill asserts surviving content, not a return word.
- The drill runs offline with no credential.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs` — which fails on a drill the register does not
  classify.

**Gate** — what must pass before approval:

- The register row is a breaker written against the behaviour, not against a return shape.
- The drill deletes only inside its own throwaway repository.

## Considerations

- The drill proves the refusal, not the transport. It cannot show that the production 403 is
  gone or that a real delete behaves identically; say so in the runbook row rather than implying
  wider coverage.
- Reuse the first ticket's seeder rather than writing a second one, and keep the sandbox's
  cleanup unconditional — a drill that leaves throwaway repositories behind on failure is how a
  container runs out of disk.

## Final Report

Development completed as planned. `verify-stranded-claim-branch` is the loop's drill for the one
mechanism whose regression **destroys work rather than delaying it**.

- **One `verify-*` arm** (step 1) over the first ticket's reproduction, seeding all three cases:
  a branch empty against the base outside `.workaholic/` (the ordinary superseded twin), a branch
  holding a file present on no other ref, and an emptiness that cannot be read.
- **The delete is allowed to actually run** (step 2). The origin is a real bare repository over
  the file transport, so `retire-claim.sh`'s `push --delete` succeeds when the proof holds; only
  the pull-request half is stubbed. The assertions are on the **refs and the file contents on
  origin afterwards**, at **both grains**, never on a return word — a row asserting the JSON
  shape would pass over a delete that happened anyway.
- **Registered** in `docs/loop-drill-runbook.md` §9 as `hermetic` with `Breaker: yes` (step 3),
  and in the operator table at the top of the runbook, with §5t-b describing what it proves and
  what it does not.
- **The CI leg is derived, not written** (step 4): `.github/workflows/loop-drills.yml` builds its
  matrix from `verify-all --list --kind hermetic`, which now enumerates this drill. A hand-listed
  leg would be the second enumeration that workflow exists to remove.
- **The failure-reason → file blame table** is the row table in §5t-b (step 5), one line per
  check naming which file a red row points at.

**The breaker was proved, not asserted** (the gate's own words). With the diff term reverted in
`claims_superseded`, both work-holding branches came back `retired: true,
remote_branch_deleted: deleted` and four rows went red including the breaker; restoring the term
turns it green. That is the loss reproduced on demand.

**What it does not prove** is stated in the runbook rather than implied: it proves the refusal
and the derivation behind it, **not the transport**. It cannot show that the production 403 is
gone or that a real remote delete behaves identically to a file-transport one.

### Discovered Insights

- **Insight**: A drill fixture for the **mission grain** must seed a ticket that names the
  mission at the branch tip. Without it `claims_mission_landed` cannot answer locally, the
  verdict falls through to `claim-merged.sh` — which the drill deliberately disables — and the
  row measures the transport's absence rather than the emptiness under test. The first run of
  this drill failed exactly there and read `report_incomplete`.
  **Context**: Any future hermetic fixture over a mission-grain claim needs the same seed and the
  same `WORKAHOLIC_CLAIM_MERGED_LOOKUP=0`.
- **Insight**: `cmd_verify_retire` and `cmd_verify_delivery_retry` share a ticket-seeding loop
  byte-for-byte, so a text-substitution edit aimed at a new drill silently landed in
  `verify-delivery-retry` instead. It was caught by running that drill, not by reading the diff.
  **Context**: `loop-drill.sh` is ~10k lines of near-identical fixture prologues; an edit to one
  drill must be anchored on something unique to it, and the neighbouring drills re-run afterwards.
