---
created_at: 2026-08-27T05:22:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-and-retire-what-the-loop-already-proved-finished
merge_policy:
verification_handoff: 
---

# Report the retry's outcome and move the token only when it delivered

## Overview

PROPOSED. Ticket 2 adds the retry; this ticket makes its outcome visible at the only surface
recording the run, and connects it to the terminal token. `/implement`'s run report already
names a `review` unit's merge outcome (`merged` / `merge_refused: <word>` /
`merge_not_attempted: <hard|confirm>`), and a `merge_refused` unit already forbids `ok`.
A retried unit must be reported in the same vocabulary rather than a second one: **delivered
by the retry** stops withholding the token, **still refused** keeps withholding it and names
the refusal, and the **scan-held** case is untouched and still reports `ok`.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the run's terminal token contract

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §6's route vocabulary and §7's token table;
  the retry's outcome joins the existing words rather than adding a set.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the exclusion counts the report
  already names; a retried unit must not read as an ordinary exclusion.
- `plugins/workaholic/skills/drive/reference/` — the run report contract.
- `CLAUDE.md` — the `/implement` row, updated in the same change.

## Implementation Steps

1. Read the whole of §7's token table and the 2026-08-27 record of why `merge_refused`
   forbids `ok` while `merge_not_attempted` does not, so this extends that rule rather than
   re-opening it.
2. Report the retried unit in §6's existing vocabulary, naming that it was a **retry**: the
   unit, the recorded refusal it was retrying, and the new outcome.
3. Token rule: a unit the retry **delivered** stops forbidding `ok`; a unit still reporting
   `merge_refused: <word>` keeps forbidding it, and the withheld token names the unit and the
   refusal, exactly as today. The scan-held case reports `ok`, unchanged.
4. Make a run that retried and reported no outcome **non-conformant on its face**, the same
   enforcement the connector retry already carries.
5. Update `drive/SKILL.md` and `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A delivered retry appears in the run report as delivered, and `ok` is reachable.
- A still-refused retry keeps `ok` withheld, and the withheld token names the unit and word.
- A scan-held unit's reporting and token behaviour are byte-identical to today's.
- No second vocabulary: the retry reports in §6's existing words.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-delivery-retry` (ticket 7)
- Read the run report over each of the three fixture states and check the token by hand.

**Gate** — what must pass before approval:

- The three states (delivered / still refused / scan-held) are told apart in the report and
  in the token, and nothing about the scan-held case moved.

## Considerations

- The failure this is written against: reporting the route alone made a scan-held pull
  request and a refused merge identical at the only surface recording the run.
- Resist a `retried: true` field on any artifact. The report is the surface; the branch story
  already carries the durable answer.
