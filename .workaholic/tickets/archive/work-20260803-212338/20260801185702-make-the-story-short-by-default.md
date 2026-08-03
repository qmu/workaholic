---
created_at: 2026-08-01T18:57:02+09:00
author: a@qmu.jp
type: enhancement
layer: [UX]
effort:
commit_hash:
category: Changed
depends_on: [20260801185701-decide-the-fate-of-low-severity-concerns.md]
mission: make-the-branch-story-concise-by-default
merge_policy: auto
---

# Make the story short when there is little to say

## Overview

The four structural changes issue #125 asks for:

1. **Fold Historical Analysis into Motivation.** Past context reads as part of the why,
   not as a section that must be filled.
2. **List only concerns above `low`** — as resolved by the decision ticket, which may
   change what "list" means for the story file versus the PR body.
3. **Leave Successful Development Patterns empty unless a pattern was really found.**
   Absent, not "None".
4. **Flatten 8-1/8-2/8-3 into one list, included only when there is something to do.**

The through-line is that a section with nothing to report should be **absent**, not padded.
The generator today fills every section with as much as it can, so a small branch gets a
long dense write-up — and a reader who learns that sections are always present stops
reading them.

The template is **mirrored in more than one place**, which is the real risk: `report/SKILL.md`
holds the story structure, `review-sections/SKILL.md` generates sections 4-7 and carries
its own JSON contract, and both ship into `outputs/`. A change applied to one mirror
produces a story whose sections disagree about their own numbering.

## Policies

- `workaholic:design` / `policies/user-experience.md` — the reader's attention is the scarce resource; a section that is always present teaches the reader to skip it.
- `workaholic:development` / `policies/review.md` — the story is the reviewer's primary artifact, and its length is a cost paid on every PR.
- `workaholic:implementation` / `policies/objective-documentation.md` — omit-when-empty is a contract, and it has to be stated the same way in every mirror.

## Key Files

- `plugins/workaholic/skills/report/SKILL.md` - the story structure and section numbering
- `plugins/workaholic/skills/review-sections/SKILL.md` - generates sections 4-7 and carries its own JSON contract
- `plugins/workaholic/skills/report/scripts/shrink-pr-body.sh` - bounds the body; its section-6 rule and its non-droppable Handoff rule both reference headings by name
- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` - parses section 6's heading verbatim
- `outputs/workflows/` - both skills ship there

## Implementation Steps

1. Apply all four changes to `report/SKILL.md`, and the same to `review-sections/SKILL.md`
   **and its JSON contract** — the fields it returns must match the sections that now
   exist.
2. Renumber deliberately, and grep for every consumer that references a heading **by
   name or number** before changing one. At least three do: `shrink-pr-body.sh` matches
   `## 6. Concerns` and `## Handoff`, and `extract-deferred-concerns.sh` parses section 6.
   A silent renumber breaks concern extraction, which fails quietly.
3. State omit-when-empty as the rule, once, and have the mirrors reference it rather than
   restate it.
4. Rebuild `outputs/` and confirm no mirror drifted.
5. Demonstrate the outcome: regenerate a story for a small branch and compare its length
   against the same branch's story before the change.

## Quality Gate

**Acceptance criteria**

- All four structural changes hold in `report/SKILL.md`, in `review-sections/SKILL.md` and its JSON contract, and in the regenerated `outputs/` bundle.
- A section with nothing to report is **absent**, not rendered as "None".
- Every consumer that references a section heading by name or number still resolves after any renumbering — `shrink-pr-body.sh` and `extract-deferred-concerns.sh` at minimum.
- A story written after the change is shorter than the same branch's story before it, with no section padded to look complete — demonstrated on a real branch, not asserted.
- Concern extraction still finds every concern the decision ticket said it should.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, including the existing `shrink-pr-body.sh` cases (which reference headings by name) and a new case asserting extraction still parses the concerns section as rendered.
- Regenerate a story for a small merged branch and record the before/after line counts.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no residual `outputs/` diff.

**Gate**

- Concern extraction still works against a story written in the new shape. Brevity that quietly breaks the extractor trades a long story for lost records.

Decided: all four changes in one ticket — they share the template and its mirrors, and landing them separately would renumber the sections twice, giving every heading-matching consumer two chances to break (developer may override at /drive).

## Considerations

- `shrink-pr-body.sh` matches `## 6. Concerns` and `## Handoff` as literal strings. Renumbering without updating it silently disables the concern-shedding path, which only shows up on an over-limit body — rare, and therefore late.
