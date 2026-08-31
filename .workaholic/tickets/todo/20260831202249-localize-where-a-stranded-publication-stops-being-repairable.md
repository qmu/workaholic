---
created_at: 2026-08-31T20:22:49+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: repair-a-mechanically-resolvable-conflict-instead-of-reporting-it
merge_policy:
verification_handoff: 
---

# Localize where a stranded publication stops being repairable

## Overview

PROPOSED. The ask reports a failure, so this ticket reproduces and localizes it before
anything is designed. The reported shape was three open proposals each conflicting on
`.workaholic/feedbacks/index.md` and the loop filing tickets rather than running the
generator. The proposal's own reading is that `conflict-class.sh` already answers
**mechanical** for a flat area's index — so the defect is one seam further out — but that
reading is a hypothesis until this ticket measures it. Nothing else in the mission may
assume which half is broken until this lands.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/ship/scripts/lib/conflict-class.sh` — the one classification
  rule; `conflict_class_generated_region` is the clause that would cover a flat area's index.
- `plugins/workaholic/skills/drive/scripts/claim-mergeability.sh` — the reader that renders
  `mergeability` per branch.
- `plugins/workaholic/skills/drive/scripts/list-catchable-claims.sh` — the candidate set the
  act draws from, and where a non-claim branch would fall out.
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — what a proposal's
  publication does when its auto-merge is refused.

## Implementation Steps

1. **Reproduce.** In a throwaway repository, build the measured shape: a base carrying a
   feedback record, and two `work-*` branches each publishing a record of their own, so both
   collide on `.workaholic/feedbacks/index.md` and on nothing else.
2. **Localize the classification.** Run the three blobs through `conflict_class_mechanical`
   and record which clause answered, and — separately — whether all three sides carry the
   `okf:generated` markers. Record the answer when a side lacks them, which is the case a
   repository on an older generator would be in.
3. **Localize the reading.** Run `claim-mergeability.sh` against each branch and record the
   verdict and `mergeability_content_files`.
4. **Localize the act.** Establish, by running it, whether such a branch appears in
   `list-catchable-claims.sh`'s candidates at all, and record the term that excludes it —
   the resume verdict, the identity, or the absence of a claim commit.
5. **Write the finding into the mission's `## Changelog`** as one line naming which of the
   three seams stops the repair, so the remaining tickets are built on a measurement rather
   than on this proposal's guess.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reproduction is a script under `scripts/e2e/` or a test row, runnable offline, that
  builds the collision without a network call.
- Each of the three seams has a recorded verdict, including the marker-absent case.
- The mission's `## Changelog` names which seam stops the repair.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- The reproduction, run twice, giving the same verdicts.

**Gate** — what must pass before approval:

- No behaviour change ships in this ticket. It measures and records; it repairs nothing.

## Considerations

- The reporter proposed two mechanisms for the first defect — regenerating the index during
  the merge (a merge driver, or a post-merge step the loop already owns), or not committing
  the generated region at all and producing it where it is read. **Both are hypotheses here,
  not the design**: this ticket may confirm that neither is needed because the classifier
  already answers mechanical, and the later tickets choose on what it measures.
- The measurement was taken on a consuming repository whose `/moderate` reports step names
  (`merge-conflicts`, `stuck-prs`) this plugin no longer has, so that repository may be on an
  older plugin. Record its plugin version if it can be established; a defect already fixed by
  an upgrade is a real and different answer.
