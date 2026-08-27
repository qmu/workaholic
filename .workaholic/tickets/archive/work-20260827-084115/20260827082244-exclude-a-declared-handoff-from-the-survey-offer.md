---
created_at: 2026-08-27T08:22:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-re-resuming-a-declared-handoff-unit
merge_policy:
verification_handoff: 
---

# Exclude a declared handoff from the survey offer

## Overview

Carry the verdict to the survey. `plan-units.sh` classifies on `resumable` first, so a
`resumable: false` verdict already drops out of `resumable[]` — what is left is to name the
exclusion honestly in `excluded[]`, so a reader can tell a unit waiting on a declared
verification from one a colleague owns or one a run is driving, and to settle what it does
to the run's terminal token.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the exclusion vocabulary and its
  header, which documents what each reason means and its next action.
- `plugins/workaholic/skills/drive/SKILL.md` §7 — the `ok` token table.
- `plugins/workaholic/skills/drive/SKILL.md` §6 — the `handoff` route, which already says the
  claim stays standing.

## Implementation Steps

1. Name the exclusion for the new verdict, in `excluded[]` with its own reason, and document
   it in the header beside `claimed_reported` / `claimed_undelivered` / `claimed_superseded`
   — a reason must imply its own next action, which is this repository's stated rule for the
   vocabulary.
2. Confirm the unit appears in `claimed[]` and in `excluded[]` and in **neither**
   `resumable[]` nor `undelivered[]` nor `resurveyed[]`: it is neither a takeover, nor a merge
   retry, nor work that came back.
3. It **does not forbid `ok`**, and say why in §7: a unit waiting on a declared human
   verification is the gate working, exactly as the scan-held pull request is — making it
   `pending` would put `ok` out of reach on precisely the runs where the machinery worked.
4. Confirm the reason lands in `backlog_all_excluded`'s per-reason counts with no second
   vocabulary, since those counts are derived from whatever `excluded[]` carries.
5. Change no other exclusion's meaning or count.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The declared unit is reported in `claimed[]` and `excluded[]` under its own reason, and is
  absent from `resumable[]`, `undelivered[]` and `resurveyed[]`.
- A run whose only outstanding item is such a unit still reports `ok`.
- Every other exclusion reason's count is unchanged over a fixture exercising them.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a survey over the fixture, asserting each of the
  four lists and the per-reason counts.

**Gate** — what must pass before approval:

- The suite passes; §7's token table states the new row and its reason.

## Considerations

- The alternative seam — an exclusion in `plan-units.sh` with no new verdict — is refused:
  every other *is this unit resumable* reading lives in the claim oracle, and putting this one
  in the survey would give the protocol two places to answer one question. `claim.sh resume`
  would also go on accepting a takeover the survey had stopped offering.
