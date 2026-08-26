---
created_at: 2026-08-26T11:32:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: tell-a-merged-claim-from-a-live-one-at-both-grains
merge_policy:
verification_handoff: 
---

# Make the oracle degrade by name, not by guess

## Overview

PROPOSED. Ticket 3 of 8. `list-claims.sh` promises that the reader degrades offline; the
new reader makes a network call, so that promise has to be kept explicitly rather than
inherited. When ticket 2's reader answers `unanswerable`, the row keeps **precisely** the
verdict it has today and the scan reports which claims it could not answer for and why.

The asymmetry is deliberate and worth stating in the code: a wrong `merged` releases work
that is still in flight; a wrong `in flight` only delays a claim. So an unread answer
never becomes `superseded`.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_scan`, where the
  reader is consulted and the verdict assembled. Its header states the degradation
  contract; extend the header in the same change.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the reported shape; the
  unanswered set is surfaced here.
- `scripts/test-workflow-scripts.mjs` — the offline case.

## Implementation Steps

1. Read `claims_scan`'s ordering comments. `superseded` sits after `claim_active` and
   before the drained fork for stated reasons; the degradation must not disturb that.
2. Consult ticket 2's reader where the verdict is decided, and on `unanswerable` leave the
   row's verdict byte-identical to today's — not `superseded`, not a new state.
3. Report the unanswered claims by name with their reasons, as a field of the scan's own
   output rather than on stderr, so a consumer can render it.
4. Bound the cost: one reader call per claim at most, and make the whole thing skippable
   so a fully offline run is not slowed by a call that cannot succeed.
5. Write the asymmetry into the header, in one sentence, beside the existing rules.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With the reader unavailable, every row's verdict is identical to the pre-change output.
- The scan names each claim it could not answer for, with a reason.
- No claim is ever reported `superseded` on a failed read.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — an offline case diffed against the
  pre-change output for byte-identity.

**Gate** — what must pass before approval:

- The offline output is proved identical, not asserted to be.

## Considerations

- Byte-identity offline is the strongest form of this and is what should be tested. A
  weaker "no row became superseded" check would pass while something else drifted.
