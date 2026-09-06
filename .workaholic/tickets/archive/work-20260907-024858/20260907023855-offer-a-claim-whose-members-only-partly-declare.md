---
created_at: 2026-09-07T02:38:55+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: hand-off-the-members-that-declare-and-drive-the-rest
merge_policy:
verification_handoff: 
---

# Offer a claim whose members only partly declare

## Overview

PROPOSED. A claim whose remaining queued work is only **partly** declared is
currently parked whole. `claims_declared_handoff` (`lib/claims.sh`) reads the one reader's
unit-level `handoff` boolean, so one declaring member out of eight answers `true`, the row
reads `awaiting_verification`, and `plan-units.sh` excludes the unit
`claimed_awaiting_verification`. The unit then reaches no offer at all, so the route step that
would drive its non-declaring members is never entered. This ticket moves the scan's reading
from *does any member declare* to *does every remaining member declare*, so a mixed unit is
offered and an all-declaring one is parked exactly as it is today.

Measured 2026-09-06 on `report-each-tick-in-the-originating-codex-chat`: 7 queued tickets,
1 declaring, `backlog_all_excluded` reporting 7 with 0 offered.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_declared_handoff`
  (~line 645) reads only `"handoff": true` / `"measurable": true` out of
  `claims_declared_reading`; the verdict site is ~line 1547 (`_cs_reason=awaiting_verification`).
- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — the one reader. It
  **already** emits `members[]` with a per-member `verification_handoff` / `probe` /
  `unmeasured`, so the partition is available without a second parser of the field.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the exclusion at ~line 419
  (`c_exc=claimed_awaiting_verification`) and its header note at ~line 120.
- `plugins/workaholic/skills/drive/reference/claims.md` — the verdict table and the
  proofs-and-judgements tables that enumerate this verdict's consumers.
- `plugins/workaholic/skills/drive/SKILL.md` — the §1 verdict table row for
  `awaiting_verification`.
- `scripts/test-workflow-scripts.mjs` — the declared-handoff axis rows that pin the verdict.

## Implementation Steps

1. **Reproduce first.** From a checkout of the base, run
   `verification-handoff.sh mission report-each-tick-in-the-originating-codex-chat` and record
   that `handoff: true` with exactly one non-empty `members[].verification_handoff` out of
   eight; run `plan-units.sh` and record `backlog_all_excluded` with the count per reason.
2. Read `lib/claims.sh`'s `claims_declared_reading` / `claims_declared_handoff` and
   `verification-handoff.sh` in full before changing either. The reader must stay the one
   parser of the field.
3. Derive the partition from the reading the scan already makes — the **remaining queued**
   members that declare, and those that do not — without a second call to the reader and
   without re-reading frontmatter anywhere.
4. Make `awaiting_verification` the verdict for a unit whose **every** remaining member
   declares. A unit with at least one non-declaring remaining member keeps its ordinary
   verdict and is offered.
5. Carry the partition onto the row so the survey can say which members hold it, and so §6
   (the next ticket) reads it rather than re-deriving it.
6. Leave every existing refusal byte-identical: a `measurable` (probe) declaration still
   answers `false` here (2026-09-06, it is re-run at §6), an unreadable read is still not a
   declaration, and no verdict word is added or removed.
7. Update `claims.md`, `drive/SKILL.md` §1 and `plan-units.sh`'s header in the same change,
   and extend the suite's declared-handoff rows to pin the mixed case in both directions.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit whose remaining queued members are a mix of declaring and non-declaring does **not**
  read `awaiting_verification` and is **not** excluded `claimed_awaiting_verification`.
- A unit whose remaining queued members **all** declare reads `awaiting_verification` exactly
  as before, and a `probe:` declaration still never reaches that verdict.
- The partition is derived from one call to `verification-handoff.sh`; no second parser of
  `verification_handoff:` exists anywhere.
- An unreadable reading is still not a declaration and parks nothing.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — new rows over a fixture repository holding a
  mixed unit, an all-declaring unit and a probe-declaring unit.
- `sh scripts/e2e/loop-drill.sh verify-all`
- The reproduction from step 1 re-run: the same mission now appears in `missions[]`.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Acceptance criteria** — the checkable conditions that must hold:

- <proposed>

**Verification method** — the commands/tests/probes that prove them:

- <proposed>

**Gate** — what must pass before approval:

- <proposed>

## Considerations

- The cost is stated rather than hidden: a mixed unit is re-offered every
  tick until its non-declaring members are driven, where before it was parked once. That is
  the intended behaviour — the six tickets are work — and it is bounded by the claim protocol,
  which refuses what is already taken.
- This ticket alone changes what is **offered**, not what is **driven**. Landed by itself, a
  mixed unit is offered and §6 still reads the unit-level `handoff: true` and hands it off
  whole — no worse than today, and the next ticket is what makes it move. Order matters.
- Do **not** move the reading into `verification-handoff.sh`'s verdict: the reader answers
  what the artifacts declare, and which members are *remaining* is the scan's question.

## Final Report

Development completed as planned.

The scan's reading moved from *does any remaining member declare* to *does every remaining
member declare*, and the partition it derives on the way now rides the claim row.

### Discovered Insights

- **Insight**: `claims_declared_reading` hands the one reader MATERIALISED TEMP FILES, so the
  reader's `members[].id` names a path under `mktemp -d` and not the artifact.
  **Context**: that is invisible while the caller wants only a boolean, and fatal the moment it
  wants to name which members a person must act on. The temp-to-artifact mapping exists only at
  the instant the blob is written, so the reading now echoes the ordered artifact paths below
  its JSON line rather than letting a consumer reconstruct them with a second walk that could
  disagree. Every existing caller takes the first line and is byte-identical.

- **Insight**: the reader's per-member `unmeasured` is exactly the test this verdict wants —
  *a non-empty declaration carrying no probe* — so the per-member probe rule came free.
  **Context**: the old `claims_declared_handoff` read the unit-level `measurable`, which is set
  from the FIRST declaring member only; a unit whose first declaration was prose and whose
  second was a probe would have parked on both. Reading `unmeasured` per member is both simpler
  and strictly more correct, and it introduced no new field anywhere.

- **Insight**: the claim row is positional TSV and three separate scripts read it by position
  (`list-claims.sh` by name, `plan-units.sh` and `claim.sh` by `read`, plus one `cut -f`).
  **Context**: adding a column silently shifted the artifact list into a boolean for two of
  them, and the resulting failure was 31 unrelated-looking assertions about claims leaving the
  backlog. The `cut -f10` site carries a comment naming its own index precisely because this
  has happened before; the two `while IFS= read` sites did not.

- **Insight**: `report-each-tick-in-the-originating-codex-chat`'s claim branch has already
  archived six of its seven tickets, so its remaining work is the one declaring ticket alone.
  **Context**: that claim therefore reads `awaiting_verification` under the new rule too, and
  correctly — the base still shows seven queued because the branch never merged. The measured
  defect is real and this ticket closes it; that particular unit is simply further along than
  the base makes it look.
