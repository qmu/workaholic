---
created_at: 2026-08-31T20:22:50+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: repair-a-mechanically-resolvable-conflict-instead-of-reporting-it
merge_policy:
verification_handoff: 
---

# Report each stranded publication in the run report

## Overview

PROPOSED. `/implement` already reports each `undelivered[]` entry with its catch-up and its
retry outcome in their own vocabularies, and each reported claim's `mergeability` so a decay
from `mechanical` to `content` is visible the hour it happens. A stranded publication is the
same fact one artifact over and appears in neither. This ticket puts it in the same report,
in the same shape, and moves no token it has no right to move.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — the run report's contract, and where the new
  per-entry obligation is stated.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — where `undelivered[]` is emitted;
  the precedent for carrying a field rather than loosening an exclusion.
- `CLAUDE.md`, `/implement` — *The run report*, which must name the new entry in the same
  change.

## Implementation Steps

1. Carry the reader's rows into the run as a **field**, exactly as `undelivered[]` is carried
   — never as a loosened exclusion, and never as a new claim verdict.
2. For each entry the run acted on, report the act's own word and then the delivery's own
   word: naming an entry and reporting no outcome for it is non-conformant on its face, the
   rule `undelivered[]` already carries.
3. Report each stranded publication's `mergeability` whether or not it was acted on, so a
   decay from `mechanical` to `content` is visible the hour it happens. Evidence, never a
   verdict.
4. Decide the token rule and state it: a **delivered** publication stops withholding `ok`; a
   refusal that waits on a person (`content_conflict`, an operator-facing publication) moves
   no token, because the person who must act is reached by the tick's question, not by the
   executor. Follow `catch_up_refused: content_conflict`, which already reads this way.
5. Update `CLAUDE.md` and `workaholic:drive` in the same commit. Outdated documentation is a
   defect here, not a follow-up.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A run that settled a stranded publication names it, the act's word and the delivery's word.
- A run that refused one names it, the refusal word, and reports `ok` or withholds it per the
  stated rule.
- Nothing is appended to the finish post; the run report is the only surface.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A read of the emitted report against `workaholic:drive`'s contract for `undelivered[]`.

**Gate** — what must pass before approval:

- No new claim verdict word is introduced, and `drive/reference/claims.md` gains no row for a
  publication.

## Considerations

- The temptation is to route this through the claim vocabulary because the shapes rhyme.
  Resist it: a publication is not a claim, `superseded` and `report_undelivered` are proofs
  about claims, and one vocabulary answering two questions is how the two drift.
- Keep the report short. A per-entry dump nobody reads is the noise this repository has twice
  retired status roots for.
