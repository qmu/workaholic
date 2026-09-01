---
created_at: 2026-08-30T08:22:51+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff: 
---

# Reproduce the claim race offline in a drill

## Overview

**Diagnosis first: the repair needs a failing proof before anything moves.** Measured
2026-08-30, `work-20260830-055314` and `work-20260830-055318` were both claimed for the unit
`draft-a-dateless-direction-with-the-operator-s-one-week-default`, four seconds apart, and each
drove the same four tickets for over an hour. Nothing in the suite or the drill set reproduces
that, so the repair would be judged against prose rather than a red test.

This ticket adds a hermetic drill that stages the race and asserts **today's** outcome: two
runners survey the same queue before either pushes, both claim, both drive, and the result is two
branches for one unit with duplicated archives. It proves nothing about the fix — that is ticket 8
— and it must be **red-by-construction against the repaired tree**, which is what makes it a proof
rather than a description.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-domain-gaps.md` — make the gap fail early

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill dispatcher; a new `verify-claim-race` verb joins its `case` arms
- `docs/loop-drill-runbook.md` §9 — the drill register `drill-register.sh` reads; the new row is classified there or `verify-all` reports `skipped:unclassified`
- `plugins/workaholic/skills/drive/scripts/claim.sh` — the seam the drill drives twice
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the oracle the drill reads back
- `scripts/test-workflow-scripts.mjs` — fails when a drill is missing from the register

## Implementation Steps

1. Reproduce by hand first, against a throwaway repository with a **bare local origin** and no
   network: seed one mission with tickets, run `claim.sh` twice from two checkouts whose
   `claims_scan` both ran before either push, and record verbatim what each call returns and what
   lands on origin. Localize before designing: the claim's branch comes from
   `branching/scripts/create.sh`, which mints `work-$(date +%Y%m%d-%H%M%S)`.
2. Add `verify-claim-race` to `scripts/e2e/loop-drill.sh`, following `verify-catch-up`'s fixture
   shape (bare origin, `gh` stubbed, no network at any point).
3. Assert the **measured** outcome as it stands today: two distinct `work-*` refs on origin, both
   carrying a `Claim` commit with the same `Unit:` trailer; `list-claims.sh` reporting the unit
   twice; and, after both runners archive, the same ticket filename under two
   `tickets/archive/<branch>/` directories.
4. Assert the loser's verdict as it reads today, so ticket 6 has a before: the mission-grain row
   answers `report_undelivered`, not `superseded`, once its twin's pull request has merged.
5. Register the drill in `docs/loop-drill-runbook.md` §9 with its classification (hermetic) and a
   `bearing` column entry, so `verify-all` runs it and `test-workflow-scripts.mjs` does not fail it
   as unclassified.
6. Confirm it runs green **on the unmodified tree** — a drill asserting today's defect must pass
   today — and note in its header that tickets 3–6 are expected to turn these assertions over.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Two runners surveying before either pushes both claim the same unit, and the drill asserts it.
- The duplicated archive is asserted by filename under two branch directories.
- The loser's mission-grain verdict is asserted as `report_undelivered`.
- The drill makes no network call and needs no credential.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-claim-race` passes on the unmodified tree.
- `sh scripts/e2e/loop-drill.sh verify-all` names the new drill and does not report `skipped:unclassified`.
- `node scripts/test-workflow-scripts.mjs` passes (register coverage).

**Gate** — what must pass before approval:

- The drill exists, is registered, is hermetic, and asserts the defect rather than the repair.

## Considerations

- **The drill must be able to fail.** A race staged by wall-clock timing is flaky; stage it by
  running each runner's survey explicitly before either push, so the ordering is the fixture's
  rather than the scheduler's.
- Ticket 8 rewrites these assertions to their post-repair form. Write them so that inversion is a
  small diff, not a rewrite.

## Final Report

Development completed as planned. `verify-claim-race` is added to `scripts/e2e/loop-drill.sh`,
dispatched by its verb, named in the usage line, and registered `hermetic` in
`docs/loop-drill-runbook.md` §9. It stages the race with **no timing at all**: runner A runs the
real `claim.sh` and pushes; A's ref is taken off the bare origin with `update-ref` so runner B's
`claims_scan` legitimately sees the origin A saw; B claims and pushes; A's ref is restored. Both
runs are the real claim act, neither is refused anything, and the ordering is the fixture's rather
than the scheduler's — which is what step 1's own Consideration required.

It asserts the defect, which is still live: two distinct `work-*` refs on origin, both carrying a
`Claim a PR-unit` commit with the same `Unit:` trailer, and the oracle reporting one unit held by
two branches. The repair that would stop the race (ticket 3) is blocked on a measured transport
refusal, so those rows are asserting today's behaviour exactly as written rather than a repair.

Two of this ticket's planned assertions moved to the tickets that own them, as its own header
anticipated ("tickets 3–6 are expected to turn these assertions over"): the loser's mission-grain
verdict is asserted in its **repaired** form (`superseded`) because ticket 6 shipped in the same
branch, and the duplicated-archive assertion is replaced by the stronger fact ticket 5 shipped —
the second runner's first write is **refused** with the tree byte-identical, so the duplicate
never reaches the base at all. Asserting a duplicate the same branch now prevents would have left
CI red by construction.

Verified: `sh scripts/e2e/loop-drill.sh verify-claim-race` passes (9 load-bearing rows, 1 breaker);
`verify-all` reports 35 drills, 0 failed, with this drill counted in the proved total;
`node scripts/test-workflow-scripts.mjs` passes (5394/0).

### Discovered Insights

- **Insight**: a claim race can be staged deterministically by editing the bare origin's refs
  between two real `claim.sh` runs, rather than by running them concurrently.
  **Context**: the only input `claim.sh` has about competitors is its own fetched view of origin,
  so reproducing the two views reproduces the race exactly — with no sleep deciding the outcome.
  Any future drill over a coordination protocol here can use the same shape.
