---
created_at: 2026-08-27T23:22:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827232222-ask-the-holder-for-the-branches-left-undeleted.md
mission: finish-the-retirement-the-loop-cannot-complete
merge_policy:
verification_handoff: 
---

# Drill the blocked retirement with no network

## Overview

`verify-retire` drills the retirement's three acts and the refusal of a judgement by
its own verdict word. It does not drill the case that has been true in production on
every tick since the mechanism landed: the delete refused, the other two acts
standing. A behaviour nothing drills is a behaviour the next change can lose.

Extend the drill with a row whose delete is refused, over local fixtures with the
transport stubbed and no network — plus one row that deliberately breaks the seam,
so the drill is proved able to fail.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testing-strategy.md` — a property is drilled, not asserted

## Key Files

- `scripts/e2e/loop-drill.sh` — `cmd_verify_retire`, the local bare origin and the
  PATH stub it already builds; the new rows extend that fixture rather than adding one.
- `docs/loop-drill-runbook.md` — the failure-reason→file blame table the new rows join.
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — the writer under drill.
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the caller
  whose summary and question the drill reads.

## Implementation Steps

1. Add a fixture whose branch delete is refused while its pull-request close
   succeeds — the production shape — using the existing stub seam, with no network.
2. Assert the **named word** from ticket 2 is what comes back, not a generic refusal.
3. Assert the **two acts that stand** are named in the caller's summary (ticket 4).
4. Assert the **question key** and its asked-once gate (ticket 5): one question on
   the first tick, none on the second, addressed to the claim holder and naming the branch.
5. Assert **nothing already done is undone**: the closed pull request stays closed,
   the claim is not released, the verdict stays `superseded`, and a re-run takes only
   the one remaining act.
6. Assert the **summary is stable** across two ticks over the unchanged fixture (ticket 6).
7. Add one row that deliberately breaks the seam — the drill must fail when the
   behaviour is lost, and that row is labelled as the intentional failure.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The blocked-delete row drills the named word, the standing acts, the question key,
  its asked-once gate, and that nothing done is undone.
- The drill makes no network call and runs from a clean checkout.
- The deliberately broken row fails, proving the drill can.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-retire`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- `verify-retire` passes on the honest rows and fails on the broken one, both shown.

## Considerations

- The drill is operator tooling outside the plugin and assumes the server's full
  `gh` and `qfs`; the new rows must keep that assumption and add no other.
- Ticket 3 may land as a recording-only finding. The drill must not assume a retry
  exists — it drills the blocked path, which is true either way.
