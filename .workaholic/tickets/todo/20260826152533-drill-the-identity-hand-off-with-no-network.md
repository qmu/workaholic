---
created_at: 2026-08-26T15:25:33+00:00
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
