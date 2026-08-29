---
created_at: 2026-08-29T07:20:45+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-closing-link-readable-as-the-corpus-grows
merge_policy:
verification_handoff: 
---

# Say no citing artifacts only when the walk completed

## Overview

PROPOSED. Carry the previous ticket's walk outcome into `attributed-work.sh`'s emitted
reading. A degraded walk reports its reason and **null** counts — the shape
`unattributed-work.sh` already uses for exactly this — rather than zeroed ones, so
`no_citing_artifacts` keeps the meaning mission `prove-the-loop-s-closing-link` gave it:
*nothing has answered this direction yet*, and nothing else.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/keep-serving.md` — null counts over zeroed ones on a read that failed

## Key Files

- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — the emitted reading:
  `count`, `active_count`, `waiting_*`, `waiting_mission_slugs`, `artifacts`, `empty`,
  `empty_reason`.
- `plugins/workaholic/skills/strategy/scripts/unattributed-work.sh` — the shape to follow;
  **read only** here.
- `plugins/workaholic/skills/strategy/SKILL.md` — the reader's contract and the meaning of
  `no_citing_artifacts`.
- `scripts/test-workflow-scripts.mjs`, `outputs/workflows/`.

## Implementation Steps

1. Emit `readable` and its reason on the reading, following `unattributed-work.sh`'s existing
   field shape rather than inventing a second vocabulary for the same idea.
2. On a degraded walk, report **null** counts for every count the walk would have produced —
   `count`, `active_count`, and each `waiting_*` — and an empty-but-explicitly-unreadable
   artifact list. A zero on a read that failed is the whole defect.
3. **Never emit `no_citing_artifacts` on a degraded walk.** The three existing empty reasons
   stay exactly what they are and keep their honest zeros for a completed walk;
   `no_feedback_refs` is decided before any walk runs and is untouched.
4. Exit 0 on a degraded read, as the layer's other readers do: a caller that cannot read is
   told, not failed.
5. Update `workaholic:strategy` so the reader's contract states the new outcome and restates
   what `no_citing_artifacts` now means and does not mean.
6. Hermetic cases: a completed walk with citations, a completed walk with none (honest
   `no_citing_artifacts`, honest zeros), and a degraded walk (reason, nulls, no
   `no_citing_artifacts`, exit 0).
7. Regenerate `outputs/` and verify.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A degraded walk reports `readable: false` with its reason, null counts, and **no**
  `empty_reason: no_citing_artifacts`.
- A completed walk that found nothing is byte-identical to today's output.
- The reader exits 0 in every case.
- `workaholic:strategy` states the outcome and the bounded meaning of `no_citing_artifacts`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A byte-diff of the completed-empty case against the pre-change output.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No consumer is changed in this ticket; each still reads what it read before, so a consumer
  that has not yet been taught the term behaves exactly as it does today.
- `Outputs Freshness` shows no diff after the rebuild.

## Considerations

- Consumers read these counts arithmetically today, so a `null` will reach code expecting a
  number. That is deliberate and is the point of the next two tickets — but it means those two
  must land in the same mission, or a degraded read turns a silent zero into a noisy error.
  Sequence them accordingly rather than shipping this one alone.
- The documentation update is not optional here: `no_citing_artifacts` is cited by name in
  `workaholic:propose` and `CLAUDE.md` as *explicitly not a refusal*, and that claim's
  precondition is exactly what this ticket establishes.

## Final Report

Development completed as planned.

A degraded walk now emits `readable: false` with its reason, **null** counts for every
count it would have produced, an empty artifact list, and `empty` / `empty_reason` both
null — never `no_citing_artifacts`, which after mission `prove-the-loop-s-closing-link`
means *nothing has answered this direction yet* and would be the exact opposite of what
happened. The check stands ahead of every derived count, so a degraded walk cannot reach
`empty_reason` at all.

The partial finding is kept **inside** the walk so it can finish, and deliberately not
emitted: a half list rendered as a list is the same collapse one step on.

**`readable` is absent on a completed walk, and that is the contract rather than an
omission** — *absent means the walk completed*, the convention this repository already
uses for `merge_policy` (absent means review) and a ticket's `status:` (absent means
queued). It is what makes the completed readings byte-identical, which the acceptance
criteria require, and it is exactly what the gate asks for: a consumer not yet taught the
term behaves precisely as it did. The skill states the read as `readable // true`, never
as a bare truth test.

The byte-diff the verification method asks for was run against the pre-change script
(`git show HEAD:…/attributed-work.sh`, placed at the same path so its sibling reader
resolution is unchanged) over the same fixture:

```
--- slug=[alpha]     byte-identical
--- slug=[uncited]   byte-identical      # the completed-empty case
--- slug=[nope]      byte-identical
```

and, on the degraded fixture, `count: 2, empty: false, empty_reason: ""` before against
`readable: false, reason: corpus_unreadable`, all counts null, `empty_reason: null`,
exit 0 after.

The hermetic case pins the completed-empty reading as a **whole object** rather than
field by field, so it fails the moment a later change adds a field there.

No consumer was changed. The next two tickets teach the survey and the residue the term;
until they land, a consumer reading these counts arithmetically sees a completed walk's
numbers exactly as before and never reaches the nulls, because every current caller runs
against a corpus it can read.

### Discovered Insights

- **Insight**: `no_citing_artifacts` is emitted from **two** places that look alike — the
  early `emit_empty` when the corpus is empty, and the final `jq` when the walk found no
  artifacts — and only the second is reachable on a repository with any artifacts at all.
  **Context**: a change that guards only `emit_empty` would leave the real path untouched
  and appear to work on an empty fixture. The guard belongs after both hops and before the
  facts section, which is where it now stands.
