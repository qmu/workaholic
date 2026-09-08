---
created_at: 2026-09-08T19:12:29+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-loop-grow-a-mission-without-handing-it-back-to-a-person
merge_policy:
verification_handoff: 
---

# Name the held publications the base has moved under

## Overview

A publication the seam holds for the operator falls out of every catch-up path:
`list-stranded-publications.sh`'s term 3 excludes, by design, whatever
`list-operator-facing-pulls.sh` claims — because that reader feeds an act that *merges*, and
merging is the operator's ruling. So the exclusion is correct and the consequence is not: nothing
anywhere says a held publication is decaying. Measured 2026-09-08: two held publications
conflicted with `main` over five hours, and one lost its target mission to the archive while it
waited. This ticket makes the decay visible; it merges nothing and moves no membership.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/list-operator-facing-pulls.sh` — the reader that
  already owns these publications, and therefore the one place the reading belongs.
- `plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` — its term 3 states
  the boundary; read it to confirm why widening *that* reader is the wrong repair.
- `plugins/workaholic/skills/drive/scripts/claim-mergeability.sh` — the one derivation of the
  four classes, composed verbatim as the stranded reader already composes it.
- `plugins/workaholic/skills/branching/scripts/lib/publication-age.sh` — the age already carried
  on a publication row; the new reading rides beside it.
- `plugins/workaholic/skills/moderate/scripts/step-operator-pulls.sh` — the step that asks
  `operator-pull:<number>`; where the reading reaches a person.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — that step's contract.

## Implementation Steps

1. **Reproduce.** Run `list-operator-facing-pulls.sh` against the current open set and record
   that a held publication is reported with its number, age and refusal word and with nothing
   that says whether the base still accepts it.
2. **Compose the class, never derive it a second time.** Carry `mergeability`,
   `mergeability_reason` and `mergeability_content_files` onto each row verbatim from
   `claim-mergeability.sh`, using the same shape `list-stranded-publications.sh` already uses.
3. **An unreadable reading is `unanswerable` with its reason, never `clean`** — the same rule the
   stranded reader states: a wrong `clean` offers an act nobody proved.
4. **Change no membership and no act.** The refusal word, the exclusions, term 3 and every
   consumer's behaviour stay byte-identical; this row is evidence.
5. **Say it where a person reads it.** Name the class and the age in `/moderate`'s
   `operator-pull:<number>` question, so a publication whose conflict is deepening is
   distinguishable from one merely waiting.
6. **Bound the cost.** The reader already pages the open pull requests and reads each one's
   files; state the added per-row cost in the header and keep it inside the existing limit.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Every operator-facing row carries a `mergeability` class composed from `claim-mergeability.sh`.
- An unreadable reading is `unanswerable` with its reason and never `clean`.
- The refusal words, the membership and every consumer's exclusions are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- No second derivation of mergeability, and no act reads the new field.

## Considerations

- The temptation is to widen `list-stranded-publications.sh` instead. That reader feeds a merging
  act, and merging a held publication discharges the operator's ruling — refuse it by name.
- The reading is evidence, never a verdict: nothing may gate, hold or close a publication on it.
