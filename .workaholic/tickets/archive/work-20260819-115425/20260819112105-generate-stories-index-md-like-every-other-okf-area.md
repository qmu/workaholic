---
created_at: 2026-08-19T11:21:05+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260819111841-generate-stories-index-md-like-every-other-okf-area.md]
merge_policy:
verification_handoff: 
claim: work-20260819-115425
---

# Generate stories/index.md like every other OKF area

## Overview

PROPOSED. `okf/scripts/refresh-index.sh` regenerates the marked region of every
flat knowledge area's index and deliberately excludes `stories/index.md` — its
header says so at line 7, and the area loop (line 187) lists
`deployments feedbacks release-notes releases strategies terms` without it. The
exclusion is well-founded today: a story's index description exists nowhere but
the index itself (the Story frontmatter carries `type`, `branch`,
`tickets_completed`, `tickets`, `mission` — no description field), so `/report`
writes the bullet by hand (`report/reference/story-structure.md` §*Updating the
stories index*; `report/reference/orchestration.md` step 4).

The cost is that the stories index is the one ledger index with **no generator**:
nothing repairs it after a merge disturbs it, nothing detects a run that wrote
its story file and never added the bullet (a consuming repository was found
missing 12 story entries and one feedback entry, by a hand-written identity
check), and ordering degrades monotonically because every run inserts at the top
and nothing normalizes afterwards. This matters more now that consumers mark the
ledger indexes `merge=union` in `.gitattributes`: union never reports a
conflict, so correctness rests on regeneration — which stories alone cannot use.

Move the description into the story's own frontmatter, have `/report` write the
field instead of the index line, and add `stories` to the generated areas.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/idempotency.md` — the regenerator must stay same-tree-in/same-bytes-out

## Key Files

- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — the area loop at line 187,
  `build_region` (ascending `LC_ALL=C sort`, `*.md` minus `index.md` only),
  `entry_line` (description from `description:` frontmatter, falling back to the
  prior region's text), `index_is_pure_generated` (the first-touch rule), and the
  header comment at line 7 that states the exclusion.
- `plugins/workaholic/skills/okf/SKILL.md` — the "It deliberately does **not** touch"
  list names `stories/index.md`; the flat-area bullet enumerates the areas.
- `plugins/workaholic/skills/report/reference/story-structure.md` — the frontmatter
  schema, and §*Updating the stories index* (line ~193) which instructs the direct write.
- `plugins/workaholic/skills/report/reference/orchestration.md` — step 4, "Update
  `.workaholic/stories/index.md`".
- `plugins/workaholic/hooks/validate-story.sh` — the write-time story floor; decide
  whether the new field is floored or optional (it grandfathers tracked files).
- `.workaholic/stories/index.md` — **carries hand-authored prose** (an intro paragraph
  and a `README.md` link), so it is NOT the purely-generated shape.
- `.workaholic/stories/README.md` — a non-story `.md` sitting in the area.
- `scripts/test-workflow-scripts.mjs` — `testRefreshIndexPreservesContent` and the
  idempotence assertions are the pattern to extend.

## Implementation Steps

1. **Confirm the two facts the reporter's plan does not account for** before
   changing anything — both were observed on this repository and either one
   silently defeats the change:
   - `.workaholic/stories/index.md` fails `index_is_pure_generated` (line 3 is a
     prose paragraph linking `README.md`), so the "lossless first-touch
     migration" the ask relies on does **not** fire: the script would preserve
     the file verbatim and generate nothing. Verify with
     `awk '/^[[:space:]]*$/{next} /^# /{next} /^\* \[/{next} {print}' .workaholic/stories/index.md`.
   - `build_region` selects every `*.md` except `index.md`, so `stories/README.md`
     would be emitted as a story entry.
2. Add the description field to the Story frontmatter schema in
   `report/reference/story-structure.md` — one line, the same text `/report`
   composes for the bullet today. **See `## Open Decisions` for the field name.**
3. Teach `refresh-index.sh` the `stories` area: add it to the flat-area loop, and
   give the loop the two per-area differences stories needs, each as a narrow,
   named knob rather than a special case buried in `build_region`:
   - **order**: filename **descending**, so `work-YYYYMMDD-HHMMSS.md` reads
     newest-first as the index does today (the shared path stays ascending).
   - **excluded entries**: `README.md` alongside the existing `index.md`
     exclusion. Applying it to every area is fine — no area indexes a README.
4. Make the entry description resolve from the field chosen in step 2, keeping
   the existing prior-region fallback exactly as it is: that fallback is what
   carries all ~195 existing hand-written descriptions across the first
   regeneration, so it must run before any story carries the new field.
5. Opt the existing `.workaholic/stories/index.md` into generation **in the same
   change**: insert `<!-- okf:generated:begin -->` / `<!-- okf:generated:end -->`
   around the current bullet list, leaving the intro paragraph outside the
   markers. Without this step nothing in steps 3–4 takes effect on this tree
   (step 1's first finding).
6. Stop `/report` writing the index directly: remove the instruction from
   `report/reference/story-structure.md` and `report/reference/orchestration.md`,
   and have the story writer emit the frontmatter field instead. `/report`
   already calls `refresh-index.sh` at its knowledge-commit seam, so the entry
   appears from the file.
7. Update the docs that state the exclusion in the same commit (the repository's
   own rule): `okf/SKILL.md`'s "It deliberately does **not** touch" list and its
   flat-area enumeration, and `refresh-index.sh`'s header comment at line 7.
8. Extend `scripts/test-workflow-scripts.mjs`: a story file with the field
   produces its entry with no `/report` involved; a second run over a clean tree
   changes nothing; a story with no field keeps the prior region's description;
   `README.md` never appears as an entry; entries come out newest-first.
9. Rebuild the generated outputs (`node scripts/build-plugins/build.mjs`) and run
   `verify.mjs`, `validate-metadata.mjs` and the smoke tests.

## Open Decisions

- **Field name: `summary:` (as the ask states) or `description:` (as every other
  area already uses)?** The ask specifies adding `summary:` to the Story
  frontmatter. The codebase's own convention is `description:` — `entry_line`
  reads exactly that key for all six generated areas, so reusing it means the
  generic reader needs no second key and stories behave identically to every
  other area; introducing `summary:` means either a stories-only key in
  `entry_line` or two keys meaning one thing. Against that: `summary:` is what
  the reporter asked for and reads better on a narrative document, and
  `description:` is already an OKF-ish term the story template does not use. The
  driving session resolves this explicitly and records the resolution in its
  Final Report — it is a one-word difference in step 2 and step 4, and nothing
  else in the plan moves either way.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Adding a story file under `.workaholic/stories/` and running `refresh-index.sh`
  produces that story's index entry, with no `/report` run involved.
- Running `refresh-index.sh` twice on a clean tree leaves the tree clean.
- An index whose entries were reordered, dropped or duplicated is repaired by
  regenerating it; entries come out newest-first and `README.md` is not among them.
- Every description currently in `.workaholic/stories/index.md` survives the first
  regeneration (via the prior-region fallback), and the intro paragraph outside the
  markers is untouched.
- `okf/SKILL.md`, `refresh-index.sh`'s header and both `report/reference/` files no
  longer instruct or describe the direct index write.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/okf/scripts/refresh-index.sh && git diff --stat` — twice.
- `git diff .workaholic/stories/index.md` after the first regeneration: bullets
  reordered/marked, no description lost.
- `node scripts/test-workflow-scripts.mjs` (with the new cases from step 8).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs`.
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The smoke tests pass and `outputs/` is regenerated (the `Outputs Freshness` CI
  workflow fails on any diff).
- The `## Open Decisions` item is resolved explicitly in the Final Report.

## Considerations

- **The stories area holds non-`work-*` filenames** (`claude-lucid-tesla-4yz3ob.md`,
  `drive-20260131-223656.md`). Descending filename sort is deterministic but is
  chronological only for the `work-YYYYMMDD-HHMMSS` shape; legacy names sort by
  prefix. Acceptable — the property that matters is determinism plus newest-first
  for current stories — but say so rather than implying full chronology.
- **The prior-region fallback is load-bearing exactly once.** If step 5 (markers)
  landed in a later change than steps 3–4, the first regeneration on a consuming
  repository could run against an index whose bullets are already gone. Keep the
  whole thing in one pull request.
- **A half-landed state fights itself**: if `/report` still inserts a bullet while
  the region is generated, the insertion is either overwritten or duplicated. This
  is the reason the work is one ticket and not a two-ticket mission.
- `validate-story.sh` grandfathers tracked stories, so flooring the new field would
  only affect new writes — but a story written without it still gets an entry (bare
  link or prior-region text), so flooring is optional and out of scope unless the
  driving session finds a reason.
