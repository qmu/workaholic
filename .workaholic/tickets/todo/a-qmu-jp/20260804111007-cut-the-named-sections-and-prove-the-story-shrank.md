---
created_at: 2026-08-04T11:10:07+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on: 20260804111006-measure-which-story-sections-carry-the-line-growth.md
mission: make-the-branch-story-measurably-shorter
merge_policy: review
---

# Cut what the measurement named, and prove the next story is shorter than the same branch's

## Overview

`20260804111006` names the sections that carry the growth. This ticket acts on that verdict and — unlike the predecessor mission's four edits — **proves the number moved before it claims to have moved it**.

The predecessor's failure is the specification for this one. It made four plausible structural edits, shipped them, and only measured months of stories later, at which point the mean had risen 29%. So the deliverable here is not "a change to the writer"; it is a change plus a measurement that repeats the first ticket's method on a story written afterwards.

**This ticket is deliberately not pre-specified beyond its gate.** Which edit is right depends entirely on what the measurement named, and writing the fix now would repeat exactly the assumption-first mistake the mission exists to correct. What *is* fixed is the shape of the acceptable answer, below.

## What the change must satisfy

Whatever the measurement points at:

- **It addresses the named cause, not an adjacent one.** If the record says section 3 carries 60% of the delta, an edit to section 6 does not close this ticket however sensible it looks.
- **It attacks the instruction, not the heading.** The predecessor removed and merged headings and the writer filled the survivors. Length is produced by what the writer is *told to write under* a heading, so the lever is the per-section guidance in `report/SKILL.md` (and `review-sections/SKILL.md` for sections 4–7) — an explicit "stop when it has said what happened" rule, a stated ceiling, or a worked short example — rather than a fifth round of restructuring.
- **An empty section stays one line.** The mission's Experience states this outright: an empty Concerns section is one line, not a paragraph explaining that there were no concerns. Whatever else changes, that must hold.
- **If the first ticket found the premise unsupported** — branch size explained the growth — then the honest form of this ticket is to record that in the mission's changelog, close the mission `achieved` on its first criterion, and make no edit. Do not manufacture a change to have shipped one.

## Proving it

Re-run `20260804111006`'s method — same binning, same derivation — over the stories written after the change lands, and state the mean against the **127-line pre-change baseline**, not against the 164-line post-change one. Beating 164 is not the goal; 164 is the regression.

The mission's second criterion is *"a story written after the change is shorter than the same branch's story"*, which is stronger than a mean and is the one to satisfy where it is available: if any branch in the corpus can have its story regenerated under the new guidance, compare those two directly. Where that is not possible, say so and fall back to the mean, with the story count stated — a mean over two stories is not evidence.

## Policies

- `workaholic:planning` / `policies/verify-before-building.md` — the predecessor shipped four unmeasured edits; this ticket does not close until the number is re-measured
- `workaholic:implementation` / `policies/objective-documentation.md` — the guidance a writer reads is the artifact being changed, so its edit is the deliverable
- `workaholic:design` / `policies/history-structures.md` — the before/after numbers belong in the mission changelog, where the next reader finds them

## Key Files

- `plugins/workaholic/skills/report/SKILL.md` — `### Story Content Structure` and the per-section templates (`## 1. Overview` … `## 8. Notes`), plus `### Writing Guidelines`
- `plugins/workaholic/skills/review-sections/SKILL.md` — sections 4–7, generated separately
- `.workaholic/missions/active/make-the-branch-story-measurably-shorter/mission.md` — the criteria and the baseline
- `.workaholic/feedbacks/` — the measurement record this ticket acts on
- `outputs/workflows/skills/report/`, `outputs/workflows/skills/review-sections/` — generated; rebuild, never hand-edit

## Related History

The predecessor mission `make-the-branch-story-concise-by-default` is in `.workaholic/missions/archive/`. Its four structural edits are on `main` and are not to be reverted by this ticket — they were not shown to be harmful, only insufficient, and reverting them would confound the new measurement with a second change.

## Implementation Steps

1. Read the measurement record; restate its verdict in one sentence at the top of the work.
2. If the premise was unsupported, take the no-edit path above and stop.
3. Otherwise edit the guidance for the named sections in `report/SKILL.md` (and `review-sections/SKILL.md` where the section lives there).
4. Rebuild `outputs/` (`node scripts/build-plugins/build.mjs`) and commit the regenerated artifacts.
5. Re-measure over stories written after the change, against the 127-line baseline.
6. Append the before/after numbers and the story count to the mission's `## Changelog` through `append-changelog.sh`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The edit addresses the section(s) the measurement named, and the work says which.
- An empty section renders as one line in the resulting story.
- A post-change measurement exists, is stated against the 127-line baseline, and names its story count.
- `outputs/` is regenerated and committed in the same change.
- No existing story file is edited to make the number look better.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean, with no `outputs/` diff remaining.
- `node scripts/test-workflow-scripts.mjs` at or above its environmental baseline.
- `git diff` shows no modification under `.workaholic/stories/` to stories predating the change.
- The mission changelog carries the before/after line.

**Gate** — what must pass before approval:

- The number moved toward 127 and the measurement backing that claim is reproducible, **or** the no-edit path was taken and recorded.

## Considerations

- **Do not revert the predecessor's edits.** Two changes at once make the next measurement uninterpretable, which is how this mission was created in the first place.
- **A mean over a handful of stories is weak evidence, and saying so is part of the deliverable.** The per-branch comparison in the mission's second criterion exists precisely because the mean is noisy at this corpus size.
- **Resist shortening by deleting sections.** The predecessor already tried structure; the sections carry information a reviewer uses. The target is padding, not content.
