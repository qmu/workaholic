---
created_at: 2026-08-27T08:22:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-re-resuming-a-declared-handoff-unit
merge_policy:
verification_handoff: 
---

# Reproduce the handoff re-resume and pin it

## Overview

Reproduce, before anything changes, the behaviour issue #651 reports: a claim whose
remaining queued ticket declares `verification_handoff:` reads `parked_with_pr`,
`resumable: true`, and is offered by `plan-units.sh` on every survey. The reporter states
this is a report and not a diagnosis, and the survey and the claim oracle each have their
own reasons for the current behaviour — so the failing case is written as a test first, and
the later tickets in this mission are judged against it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the failing case lands here,
  built from the existing claim fixtures.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_scan`'s verdict chain;
  the `parked_with_pr` branch is the last one before `heartbeat_lapsed`.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — `resumable[]` and
  `claimed_resumable`, which is what turns the verdict into an hourly offer.
- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — the reader that
  already answers the question from the artifact.

## Implementation Steps

1. **Reproduce.** Build a hermetic fixture in the suite's existing style: a base, a
   `work-*` claim branch whose tip carries a committed `.workaholic/stories/<branch>.md`,
   one archived ticket, and one still-queued ticket declaring a non-empty
   `verification_handoff:`. Assert what happens today — `claims_scan` answers
   `parked_with_pr` with `resumable: true`, and `plan-units.sh` lists the unit in
   `resumable[]`.
2. **Localize.** Confirm from the fixture which reading produces it: `claims_has_work`
   answers `true` because a queued ticket still names the unit, `claims_has_story` answers
   `true`, and nothing in the chain reads `verification-handoff.sh`. Record what each
   reader answered, so the later tickets change one of them rather than guessing.
3. **Pin it.** Land the reproduction as a test that asserts today's behaviour and is
   inverted by the ticket that fixes it, so the defect becomes a fact a change can lose
   rather than a claim in prose.
4. Keep the fixture offline: no `gh`, no network, no touch of the working tree — the
   suite's standing contract.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A hermetic fixture reproduces the offer: `parked_with_pr`, `resumable: true`, and the
  unit present in `plan-units.sh`'s `resumable[]`.
- The reproduction names which reader produced each half of the verdict.
- The test is inverted by this mission's fix rather than deleted by it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` passes with the new case present.
- The new case fails when the fixture's `verification_handoff:` value is emptied, proving
  it keys on the declaration and not on the fixture's shape.

**Gate** — what must pass before approval:

- The suite runs green, creates its repositories under the OS temp dir, and makes no
  network call.

## Considerations

- The reporter's proposed mechanism — a reading in the claim protocol that consults the
  declaration — is a **hypothesis** here, not this ticket's design. It is corroborated by
  reading `lib/claims.sh` (the `parked_with_pr` branch consults `claims_has_work` and
  `claims_has_story` and nothing else), but the fixture is what settles it.
- If the reproduction shows a different cause, this mission's later tickets are replanned
  rather than driven; say so in the run report instead of forcing the plan.
