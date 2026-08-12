---
created_at: 2026-08-12T20:42:16+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-routine-finish-line-from-vanishing-on-the-script-path
merge_policy:
---

# Report an unposted finish line as unposted

## Overview

PROPOSED. The second half of the ask: "surface a `no_token` outcome in the run
report instead of treating it as posted."

Even once ticket `20260812204122` fixes which surface a run posts through, a post
can still fail — no connector selected, no token, a Slack API error. Today that
failure is invisible from outside the run:

- `skills/propose/reference/workflow.md` step 13 does report a `notified` flag —
  the good precedent.
- `skills/drive/SKILL.md` §7's run report has **no** notification field at all. Its
  per-unit report carries route, ticket outcomes, commits and PR URL, and its last
  two lines are the `N units: X shipped, Y PR'd, Z blocked` reconciliation and the
  terminal token. A finish line that never posted changes none of them, so a run
  whose whole Slack output vanished still reads as a clean `ok`.

The measured cost is exactly that: the 18:48 UTC `[Implement]` run got
`{"notified": false, "reason": "no_token"}` and nothing downstream said so.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` §7 *Account, reconcile, and the
  terminal token* — where the run report's fields are specified
- `plugins/workaholic/skills/drive/reference/routing.md` — the full per-unit report
  field list §7 defers to
- `plugins/workaholic/skills/propose/reference/workflow.md` step 13 and
  `skills/propose/SKILL.md` — the existing `notified` precedent to align with
- `plugins/workaholic/skills/notify/SKILL.md` — the outcome vocabulary a report
  field would name

## Implementation Steps

1. **Reproduce the blind spot.** Drive a unit end-to-end with no Slack surface
   available and confirm the run report and terminal token are byte-identical to a
   run whose post landed — that identity is the defect, and it is what the fix has
   to break.
2. **Localize the seam.** Read `drive/SKILL.md` §7 and
   `drive/reference/routing.md` and name the exact per-unit report field list the
   notification outcome would join, plus whether the reconciliation line or the
   token should change at all.
3. Add a per-unit **notification outcome** to the run report — the surface used and
   the outcome (`posted` / the failure reason such as `no_token`), one per thread
   posted into, following the `notified` shape `/propose` already reports.
4. Mirror it in `propose/reference/workflow.md` step 13 if the transport rule from
   ticket `20260812204122` gives it a second surface to name.
5. **Decide the token deliberately, and write the decision down**: a notification
   is documented as never load-bearing, so an unposted line should *not* by itself
   flip `ok` to `pending` — but it must be visible in the report above it. State
   this in §7 rather than leaving it to be re-derived.
6. Update `CLAUDE.md`'s `/implement` row and `docs/drive-loop-runbook.md` if either
   describes the report's fields, then regenerate `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A run whose finish post did not reach Slack names that fact, with its reason, in
  its own run report.
- The terminal token's contract is unchanged and says so explicitly — the report
  gets more honest without the `/goal /implement ok` contract shifting underneath
  a caller-side loop.

**Verification method** — the commands/tests/probes that prove them:

- The step-1 reproduction re-run: the two run reports now differ, in the
  notification field only.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The step-5 decision on the terminal token is written into `drive/SKILL.md` §7,
  not just into the branch story.

## Considerations

- Ordering: this ticket is second. Ticket `20260812204122` decides which surfaces
  exist, and this one reports which of them worked — reporting an outcome before
  the outcome's vocabulary is settled would need rewriting.
- Keep the reconciliation line's shape (`N units: X shipped, Y PR'd, Z blocked`)
  untouched; it is a contract an external loop parses.
