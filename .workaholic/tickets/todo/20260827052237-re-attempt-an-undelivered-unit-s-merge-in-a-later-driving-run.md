---
created_at: 2026-08-27T05:22:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-and-retire-what-the-loop-already-proved-finished
merge_policy:
verification_handoff: 
---

# Re-attempt an undelivered unit's merge in a later driving run

## Overview

PROPOSED. `report_undelivered` (2026-08-27) means the loop finished a unit and the transport
refused its merge. The run that attempted it retries once in-session under the one named
precondition (`session_type_cannot_merge`), and **no later run ever retries**:
`plan-units.sh` excludes the unit `claimed_undelivered` at every later survey, and
`claim.sh resume` refuses it by its own name. So a green, finished, undelivered unit is
delivered by nobody until a human opens the pull request and presses the button.

This ticket gives `/implement` a bounded retry for exactly that verdict: read the recorded
refusal off the branch story, attempt the merge once through the seam that refused it, and
record the new outcome. It **never overrides a gate** — a `hard` or `confirm` scan finding
is a pull request waiting on a person by design, not a refused delivery, and is never touched.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the delivery seam and its named refusals

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — emits `report_undelivered` and,
  on the row, the `merge_outcome` this retry reads; the precondition is that word.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — excludes the unit
  `claimed_undelivered` today; must offer it for the retry without offering it for a drive.
- `plugins/workaholic/skills/drive/SKILL.md` — §6's route and the `/implement` contract.
- `plugins/workaholic/skills/story/scripts/record-merge-outcome.sh` — where the new outcome
  is recorded; already idempotent and already replaces rather than stacks.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport.
- `CLAUDE.md` — the `/implement` row and the Claim protocol section.

## Implementation Steps

1. Read `lib/claims.sh`'s `claims_merge_outcome` and the row shape it produces, so the retry
   reads the recorded refusal rather than re-deriving one. Read the whole of
   `drive/reference/claims.md`'s `report_undelivered` record before designing the offer.
2. Decide where the unit surfaces. It must reach the retry **without** becoming drivable
   backlog: the queue is drained and its tickets are archived, so a takeover is wrong. Prefer
   a named field beside `resurveyed[]` over loosening `claimed_undelivered`, and state the
   choice in `plan-units.sh`'s header.
3. Gate the retry on the recorded outcome being a **refusal**, never a scan hold: a
   `merge_not_attempted: hard|confirm` row is skipped by name and reported as skipped.
4. Attempt the merge **once**, through the same REST seam that refused it, with the existing
   `session_type_cannot_merge` connector retry unchanged behind it (`rules/shell.md`'s one
   qualification — its bounds do not move).
5. Record the new outcome with `record-merge-outcome.sh`, so a still-refused unit keeps a
   current answer on its branch and a delivered one releases its claim by merging.
6. Bound it: one attempt per unit per run, and no attempt at all when the row's verdict is
   anything but `report_undelivered`.
7. Update `drive/SKILL.md` and `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A claim reading `report_undelivered` whose recorded outcome is a refusal gets exactly one
  merge attempt in a later run.
- A row recording `merge_not_attempted: hard` or `confirm` is never attempted and is reported
  as skipped by name.
- No verdict other than `report_undelivered` reaches the retry; no gate is overridden.
- The unit is never re-driven and no archived ticket is re-claimed.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-delivery-retry` (ticket 7 adds it)
- Read `plan-units.sh`'s output on a fixture holding one `report_undelivered` claim and one
  scan-held claim, and confirm only the first is offered.

**Gate** — what must pass before approval:

- The retry reads the verdict word from `lib/claims.sh` and the proof/judgement table
  (ticket 1), never a re-derivation, and the scan-held case is refused by name.

## Considerations

- The measured failure this answers: four green pull requests the loop opened on 2026-08-26
  were still open and undelivered a day later, with `ok` reported over all of them.
- A merge is an outward-facing act. The bound that keeps it safe is that the unit is already
  finished, already reported, already at an open pull request the loop itself opened, and the
  refusal that stopped it is recorded on the branch — not inferred.
- Do not widen the retry to `queue_drained`: that verdict means *waiting on a person*, and it
  is a judgement, not a proof.
