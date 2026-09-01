---
created_at: 2026-08-29T21:20:56+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-lifecycle-a-declared-stage
merge_policy:
verification_handoff: 
---

# Record a direction's declared stage on the artifact

## Overview

PROPOSED. The stage is the operator's **declared** phase, so it is recorded on the
artifact rather than derived from evidence: a `stage:` frontmatter field on
`.workaholic/strategies/<slug>.md`, from the closed set `進行中 | 改良中 | 観察中`,
in the operator's own vocabulary and kept verbatim.

**Absent means 進行中** — the convention `merge_policy` (absent means review), a
ticket's `status:` (absent means queued) and `attributed-work.sh`'s `readable`
(absent means the walk completed) already use. That is what makes this a field
addition with **no migration**: every committed strategy stays valid, and the one
live direction reads as it always has.

`create.sh` gains `--stage`; `read.sh` is the one reader of the field, exactly as it
is the one reader of `feedback_refs`. The write floor holds the closed set, and
grandfathers git-tracked files as its siblings do.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/data-handling.md` — one field, one reader, one closed set

## Key Files

- `plugins/workaholic/skills/strategy/SKILL.md` — *The model* gains the fourth part and
  states the absent-means-進行中 convention beside the three existing ones.
- `plugins/workaholic/skills/strategy/scripts/create.sh` — the first writer; takes
  `--stage`, refuses a value outside the closed set (`bad_stage`), writes nothing on a
  refusal, and omits the line entirely when no stage was named.
- `plugins/workaholic/skills/strategy/scripts/read.sh` — the one reader; emits `stage`,
  resolving an absent field to `進行中` in one place so no consumer re-derives it.
- `plugins/workaholic/skills/strategy/scripts/list.sh` — carries `stage` on each row, so
  the set read at `/specificate` step 5b already answers it.
- `plugins/workaholic/hooks/validate-strategy.sh` — the write-time floor; a `stage:`
  present and outside the closed set is refused, an absent one passes, git-tracked files
  stay grandfathered.
- `plugins/workaholic/rules/workaholic.md`, `CLAUDE.md` — the artifact's documented shape.

## Implementation Steps

1. Read `strategy/SKILL.md` *The model* and *The write-time floor* whole, plus
   `create.sh` and `validate-strategy.sh`, before writing anything — the three-part
   model and the refusal names are what this extends.
2. Add the closed set and the absent-means-進行中 rule to `SKILL.md`'s model table as a
   fourth row, stating that the stage is **declared, never derived**, and that no
   reading in the lifecycle layer becomes the stage by itself.
3. Teach `create.sh` `--stage <value>`: validate against the closed set, refuse
   `bad_stage` with nothing written (its existing discipline), and emit no `stage:` line
   at all when the flag is absent, so an unstaged strategy is byte-identical to today's.
4. Teach `read.sh` to emit `stage`, resolving absent to `進行中` **there and nowhere
   else**, so the default has exactly one derivation.
5. Carry `stage` onto `list.sh`'s rows from `read.sh`, never by a second parse.
6. Extend `validate-strategy.sh` with the closed-set check only — presence is never
   required, because absence is a valid, meaningful state.
7. Update `rules/workaholic.md` and `CLAUDE.md` in the same change.
8. Add hermetic coverage to `scripts/test-workflow-scripts.mjs`: each of the three
   values round-trips, an absent field reads `進行中`, a bad value refuses with the file
   byte-identical, and an already-committed strategy with no `stage:` still validates.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A strategy created with `--stage 改良中` reads back `改良中`; one created without the
  flag carries no `stage:` line and reads back `進行中`.
- A value outside the closed set is refused `bad_stage` with the artifact and the index
  byte-identical.
- Every strategy already on `main` still passes `validate-strategy.sh` unchanged.
- `read.sh` is the only place the absent default is resolved.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No migration script is added and no existing strategy file is rewritten.
- Nothing but `create.sh` writes the field in this ticket; the writer set stays three.

## Considerations

- The Japanese values are the operator's vocabulary and are kept verbatim; an ASCII
  alias set would give one field two spellings and is the drift this avoids.
- Whether `amend.sh` may move the field is the **next** ticket's subject, deliberately:
  recording the field and moving it are two acts with two writers.

## Final Report

Development completed as planned.

The field, its one writer, its one reader and the write floor. `create.sh` takes `--stage`
before its positionals so the positional contract does not move; `read.sh` resolves an absent
field to 進行中 in one place; `list.sh` composes that reader rather than parsing the field a
second time; `validate-strategy.sh` checks only the closed set, never presence.

### Discovered Insights

- **Insight**: `validate-strategy.sh` grandfathers every **git-tracked** file, and
  `create.sh` runs `git add` on what it writes — so validating a strategy the test just
  created proves nothing about the floor at all. The first version of this ticket's floor
  assertion passed over a deliberately broken value for exactly that reason.
  **Context**: every write-floor hook in this plugin shares the grandfathering rule, so any
  test of any of them must write its candidate **untracked and by hand**. A test that creates
  its fixture through the artifact's own writer is testing the writer twice and the hook
  never. The block here does that and states why in place.

- **Insight**: `mission/scripts/slug.sh` drops non-ASCII, so three strategies titled with the
  three stage words all slugify to the same stem and the second and third `create.sh` calls
  refuse `exists`.
  **Context**: it surfaced while round-tripping the closed set by hand — a fixture that looked
  like it exercised three values exercised one. Any fixture distinguishing artifacts by a
  Japanese title needs an ASCII-distinct title; the values themselves are unaffected, since
  they live in the frontmatter rather than in the slug.
