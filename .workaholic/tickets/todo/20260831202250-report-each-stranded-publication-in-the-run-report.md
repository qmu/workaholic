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

## Final Report

Development completed as planned. `workaholic:drive` §1 now reads
`list-stranded-publications.sh` **once per run**, §6 acts on each `mechanical` entry through
`settle-stranded-publication.sh` **once**, §7 states the per-entry reporting obligation, and
the token table gains three rows. `CLAUDE.md`'s */implement — the run report* section carries
the same contract, in the same change.

**Carried as a field, never as a loosened exclusion or a new claim verdict** — the rule
`undelivered[]` already carries. **Decided here and recorded**: the reader is invoked by the
run in §1 rather than emitted by `plan-units.sh`, following `list-operator-facing-pulls.sh`
rather than `undelivered[]`. The survey is offline by construction, and a per-pull REST read
inside it would make the claim survey need a credential — which is exactly why the
operator-facing reading is not in there either. The ticket's requirement is met in substance:
the rows reach the run as a list of facts, read once, reported per entry.

**The reporting obligation**: each publication's `mergeability` **whether or not the run acted**
(so a decay from `mechanical` to `content` is visible the hour it happens — evidence, never a
verdict), and, for each one acted on, the act's own word (`settled` / `already_current` /
`settle_refused: <word>`) followed by the delivery's own word (`merged` /
`merge_refused: <word>` / `not_attempted`). Naming a publication the run acted on and reporting
no outcome for it is non-conformant on its face — the enforcement every act in §7 already
carries, and the only one available where no mechanical check tells a real attempt from a
claimed one. An `ok: false` reading is reported as unreadable by its reason and never as
*nothing stranded*.

**The token rule, decided and stated** (three rows): a publication this run **settled** whose
delivery reports `merge_refused: <word>` forbids `ok` — the loop brought it back onto the base,
pushed it, and still could not deliver it, which is a `review` unit's refused merge one artifact
over; a **delivered** one stops withholding `ok`, the retry row's reasoning unchanged; and a
refusal that waits on a person (`content_conflict`, `not_mechanical:*`, an operator-facing
publication, or a run that never acted) moves **no** token, on `catch_up_refused: content_conflict`'s
own reasoning — `/implement` may not ask, and the person is reached by `/moderate`'s
`stranded-publication:<number>` question.

**No new claim verdict word, and `drive/reference/claims.md` gains no row.** A publication is
not a claim; `superseded` and `report_undelivered` are proofs about claims, and one vocabulary
answering two questions is how the two drift. Nothing is appended to the finish post — the run
report is the only surface — and the entry is kept to one short line per publication.

**Verified**: `node scripts/test-workflow-scripts.mjs` (the base-reading and step-registration
rows that pin `workaholic:drive`'s and `run.sh`'s prose still hold), plus
`node scripts/build-plugins/build.mjs` and `verify.mjs` for the regenerated bundle.

### Discovered Insights

- **Insight**: the rule that a reading "moves no token" is not a default — three of this
  repository's readings gate nothing and two forbid `ok`, and the difference is always
  *whose* fact it is.
  **Context**: a refused delivery on work **this run pushed** is the run's own outcome; a
  collision waiting on a person is not. Writing the row's reasoning beside it is what stops a
  later reader "fixing" the omission in either direction.
- **Insight**: `plan-units.sh` is deliberately credential-free, and that is why two of the
  run's once-per-run readings live in the agent rather than in the survey.
  **Context**: the tempting symmetry with `undelivered[]` would have put a per-pull REST read
  inside the one script every executor calls first, and a survey that needs a token is a
  survey that degrades where it must not.
