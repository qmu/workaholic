---
created_at: 2026-08-26T11:32:04+00:00
status: done
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

## Final Report

Development completed as planned. No merged claim is offered for resumption at either grain, and
the refusal says why.

**The ordering needed no change and was confirmed rather than assumed.** `superseded` already
sits after `claim_active` and before the drained fork, which is exactly where it has to be for
both `parked_with_pr` and `report_incomplete` to be pre-empted; the header argues that placement
and this ticket relies on it. What the previous ticket added was the mission grain's ability to
*reach* `superseded` at all.

**`claim.sh resume` refuses by name, and two neighbouring reasons were wrong in the same way.**
`superseded` fell into the `case`'s default and was reported as `identity_unresolved` — a
generic denial that sends the operator looking for a live run that does not exist. It now has
its own reason and detail. `shallow_history` was falling into the same default and gets its own
too, and the default no longer asserts a cause: an unrecognised verdict is reported as
`not_resumable` carrying the scan's own reason verbatim, so the next verdict added to the scan
cannot be mis-reported as a missing git identity.

**`claim.sh` also had to set `CLAIMS_FETCH_OK`.** It refuses outright without a reachable
origin, so reaching the resume path means the fetch ran — but the flag was lost to the command
substitution exactly as it was in the other two callers, and without it `resume` could never
see a `superseded` claim.

**Both tiers are covered, on the grain that needed it.** The mission claim is driven to
`parked_with_pr` (story at the tip, work queued) and then to `report_incomplete` (story removed,
queue drained), and each is asserted twice: resumable with the lookup answering `not_merged`,
`superseded` with it answering `merged`. The last assertion is the one that keeps this from
being a blanket refusal — a genuinely in-flight claim is still offered — and it is deliberately
last, because a change that simply stopped offering claims would pass everything above it.

**Measured on this repository after the change.** The survey now reports
`make-the-draft-release-note-an-agent-s-release-plan`, `make-workaholify-converge-the-account-s-routines`
and `make-a-rename-a-registry-entry-not-a-sweep` as `superseded` — all three previously
`queue_drained` or `parked_with_pr` — and `resumable` is empty. That is the measured defect
gone, on the units it was measured on.

### Discovered Insights

- **Insight**: A `case` default that names a specific cause is a latent mis-report. This one said
  `identity_unresolved` for every unrecognised verdict, so two real verdicts were reported as a
  missing git identity for as long as they existed.
  **Context**: A default over a closed vocabulary should either enumerate every member or report
  the input verbatim. The fix here does both — the known members are enumerated and the default
  carries the scan's own reason — so adding a verdict to the scan without adding a case produces
  an honest report rather than a wrong one.
