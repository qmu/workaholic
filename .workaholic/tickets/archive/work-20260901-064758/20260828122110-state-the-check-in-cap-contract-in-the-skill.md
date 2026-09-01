---
created_at: 2026-08-28T12:21:10+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# State the check-in cap contract in the skill

## Overview

The cap's contract was implicit and therefore unmaintainable — a value named `asked_today`
counted all time for days with nothing saying which day it was supposed to mean. Write the
contract where the step is documented, so the next reader can check the code against it.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/SKILL.md` — the check-in step's contract
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the header, beside the
  four gates it already documents
- `CLAUDE.md` — the `/moderate` row, updated in the same change

## Implementation Steps

1. State **which day the cap counts** and that it is derived once, naming the zone and the
   axis the implementation actually uses (ticket 2's decision — the tick id's UTC day, or
   the quiet-hours zone's, whichever landed). Say it in one place; the others reference it.
2. State that a **spent cap holds rather than drops**, and that a held question is
   **re-offered on the next tick** — true today and written nowhere.
3. State the drain order (ticket 3): oldest-held first, under the unchanged per-tick cap,
   and that this changes order and never eligibility.
4. State what a check-in that delivered nothing reports (tickets 4 and 5), and that a
   degraded read is named rather than rendered as a delivery.
5. Update `CLAUDE.md`'s `/moderate` row in the **same commit** — the repository's own rule
   that outdated documentation is a defect.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The skill states which day the cap counts, in the zone the implementation uses.
- The hold-and-re-offer behaviour and the drain order are written down.
- `CLAUDE.md` and the skill agree with the shipped code.

**Verification method** — the commands/tests/probes that prove them:

- Read the three documents against `ask-question.sh` and confirm no statement is false.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` —
  the generated bundle carries the updated skill.

**Gate** — what must pass before approval:

- No behaviour changes in this ticket; documentation only.

## Considerations

- Say **why** the cap exists as well as what it does: the repository has retired two
  status roots for spending a person's attention on restatement, and a later reader who
  knows only the mechanism will eventually remove the bound rather than fix its arithmetic.
- Regenerate `outputs/` if the skill text moved — the `Outputs Freshness` CI fails on drift.

## Final Report

**The work is already on the base**, landed while proposal #688 sat stranded. Verified:

`workaholic:moderate`'s SKILL.md states the contract where the step is documented — the
per-tick cap and the daily bound and which day the daily bound counts, that a spent cap
**holds** rather than drops, the working-day gate, the measured jam with its numbers
(`count: 12, days: 5` against a cap of 10), the repair as *a bound passed to a reader that
already accepted one*, and the four alternatives it was deliberately not (a raised cap, a
second reader, a stored cursor, a second notion of a day). The over-count direction at the
day boundary is stated so a later reader does not "fix" it the other way.

That is what this ticket asked for: the next reader can now check the code against a written
contract rather than infer one from a variable name. Nothing was re-implemented.
