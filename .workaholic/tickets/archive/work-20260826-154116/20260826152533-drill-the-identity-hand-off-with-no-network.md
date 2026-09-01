---
created_at: 2026-08-26T15:25:33+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826152528-stamp-only-an-address-the-loop-can-drive.md
mission: drive-the-work-the-loop-wrote-one-resolution-of-who-a-person-is
merge_policy:
verification_handoff: 
---

# Drill the identity hand-off with no network

## Overview

PROPOSED. The link this mission repairs runs across three components — the issue's assignee,
the address `/specificate` stamps, and the survey that offers the unit — and it broke **in the
seam**, not inside any one of them. Each component was internally consistent; nothing tested
the walk end to end, so the break was invisible for five days while every hourly tick reported
a clean survey.

Per-script tests will not catch the next one. This ticket pins the **walk**, so the link can
still be lost but can no longer be lost silently. It is the same move
`prove-the-loop-s-closing-link` made for the carry-forward chain.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; it already carries the ask → reader
  → scaffold → floor chain test, which is the shape to follow.
- `scripts/e2e/loop-drill.sh` — the operator drill; `verify-direction-health` and
  `verify-merged-claim` are the most recent additions and show the fixture-plus-stub pattern.
- `plugins/workaholic/skills/gather/scripts/identity.sh` — ticket 1's reader.
- `plugins/workaholic/skills/specificate/scripts/scaffold-*.sh` — the writers.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the survey that closes the walk.

## Implementation Steps

1. Add a hermetic case to `scripts/test-workflow-scripts.mjs` walking **issue assignee → the
   address the writer stamps → the survey that offers the unit**, for all three inputs:
   - a **canonical** address → stamped canonical, offered to that identity;
   - a **mapped alias** → stamped canonical, offered to that identity;
   - an **unmapped** address → `assignees: []`, the named `assignee_unmapped` report, and the
     unit offered as team-owned rather than excluded.
2. Assert the **failure** direction too, not only the success: a stamped address absent from the
   mapping must make the case fail. A test that only proves the happy path would have passed
   throughout the five stranded days.
3. Add `sh scripts/e2e/loop-drill.sh verify-identity-handoff` over a fixture with the transport
   stubbed — **no network**, following the two most recent drills' pattern.
4. Document the drill in the loop-drill runbook's verb list, in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The hermetic case covers all three inputs and asserts the stamped address, the report line and
  the survey's offer for each.
- Dropping the resolution (stamping an unmapped address) makes the case fail.
- `verify-identity-handoff` runs with no network and no credential.
- The drill's verb is documented alongside the existing ones.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — passes.
- `sh scripts/e2e/loop-drill.sh verify-identity-handoff` — passes offline.
- Deliberately break the resolution locally and confirm both fail.

**Gate** — what must pass before approval:

- Both commands pass, and both fail when the resolution is removed.

## Considerations

- **A test that cannot fail is documentation.** Step 2 exists because the whole value here is
  catching a regression in the seam; prove the test fails on the broken tree before landing it.
- The drill assumes the server's full `gh`, like the rest of `loop-drill.sh` — it is operator
  tooling outside the plugin and ships to no other agent. Keep the hermetic case in
  `test-workflow-scripts.mjs` as the one that must pass everywhere.

## Final Report

Development completed as planned, including step 2's requirement that the test be proved to
fail on a broken tree before landing.

A hermetic case in `scripts/test-workflow-scripts.mjs` walks **issue assignee → the address
the writer stamps → the survey that offers the unit** for all three inputs — a canonical
address, a mapped alias and the login itself all stamp the canonical address and reach the
survey; an unmapped login produces `assignees: []`, stamps no invented address, and is offered
as claimable rather than excluded. `sh scripts/e2e/loop-drill.sh verify-identity-handoff` runs
the same walk over a throwaway repository with no network and no credential, and the runbook's
verb list and a §5j section document it beside `verify-direction-health` and
`verify-merged-claim`.

**The failure direction is drilled, and was proved rather than asserted.** Both the hermetic
case and the drill carry a row that deliberately stamps an address the mapping does not name
and requires the survey to exclude it. Beyond that, the resolution was removed from a copy of
the tree (`identity.sh`'s alias pass disabled) and both commands were run against it: the
suite failed **33** assertions and the drill failed 4 of 10 load-bearing rows. On the intact
tree both pass. The sabotaged copy lived outside the checkout and the original was restored
byte-identical, verified by checksum.

The mission and the loose ticket are drilled for different things: a mission is not drivable
until a human's interrogation gives it an acceptance plan (`no_plan`), so the mission half is
checked for the address it **stamps** and a loose ticket for the address the survey **acts on**.

### Discovered Insights

- **Insight**: the drill's fixture had to be built around what makes a unit *offerable*, not
  just *written*. A freshly scaffolded mission is excluded `no_plan` and its tickets
  `mission_member`, so a walk that emitted a mission and asked whether the survey offered it
  would have failed for a reason with nothing to do with identity.
  **Context**: the survey's exclusion vocabulary is rich, and a seam test that asserts "was it
  offered" has to know which exclusions are the subject and which are the fixture's own.

- **Insight**: a suite that takes minutes to run cannot be iterated against a sabotaged tree in
  place. Copying `plugins/`, `scripts/` and the manifests into a temp directory reproduces
  `REPO_ROOT` exactly (it resolves from the test script's own path), so the broken-tree proof
  runs concurrently and the real checkout is never touched.
  **Context**: this is how step 2's "confirm it fails on the broken tree" was done without a
  window in which the working tree held a deliberately broken script.
