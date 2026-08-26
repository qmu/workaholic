---
created_at: 2026-08-26T11:32:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: tell-a-merged-claim-from-a-live-one-at-both-grains
merge_policy:
verification_handoff: 
---

# Never offer a merged claim for resumption

## Overview

PROPOSED. Ticket 5 of 8. `parked_with_pr` and `report_incomplete` must not answer
`resumable: true` for a claim whose pull request is merged. Measured on
`make-workaholify-converge-the-account-s-routines`, offered today as resumable with
`resume_reason: parked_with_pr` while its pull request #537 merged five days ago — a run
taking that offer spends a full cycle producing a pull request whose only correct outcome
is to be closed.

`superseded` sorts ahead of both, and the survey excludes the unit **by name**.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the verdict ordering in
  `claims_scan`; `superseded` already sits after `claim_active` and before the drained
  fork, which is where it must stay.
- `plugins/workaholic/skills/drive/scripts/claim.sh` — the `resume` path, which refuses by
  reason; a merged claim needs its own refusal rather than a generic one.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the survey's exclusion set,
  where `claimed_superseded` already exists.
- `scripts/test-workflow-scripts.mjs` — cases for both resumable reasons.

## Implementation Steps

1. Read the verdict ordering and its comments. The placement of `superseded` is argued in
   the header; this ticket relies on that placement rather than changing it.
2. Confirm `superseded` is reached before `parked_with_pr` and `report_incomplete` for a
   merged claim, and make it so if it is not.
3. Make `claim.sh resume` refuse a `superseded` claim with its own named reason, so an
   operator reading the refusal learns the pull request merged rather than seeing a
   generic denial.
4. Confirm the survey excludes it as `claimed_superseded` — the existing reason, not a new
   one — and that the exclusion is named in the run report rather than silent.
5. Cover both paths in the suite: a merged claim that would have read `parked_with_pr`,
   and one that would have read `report_incomplete`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A merged claim reads `superseded`, never `parked_with_pr` or `report_incomplete`.
- `claim.sh resume` refuses it by name.
- The survey excludes it as `claimed_superseded`, named in the report.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — both reasons covered.
- `bash plugins/workaholic/skills/drive/scripts/plan-units.sh` on this repository no
  longer offers the measured unit.

**Gate** — what must pass before approval:

- A claim that is genuinely in flight is still offered — the change must not be a blanket
  refusal to resume.

## Considerations

- `report_incomplete` was added precisely to make a drained, unreported claim a mandatory
  takeover. This narrows it rather than reversing it: a *merged* claim has nothing to
  report on, which is why the first run to hold that tier produced a doomed pull request.
