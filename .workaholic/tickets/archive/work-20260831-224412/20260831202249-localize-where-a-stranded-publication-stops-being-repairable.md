---
created_at: 2026-08-31T20:22:49+00:00
status: done
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

## Final Report

Development completed as planned. The reproduction is a hermetic row in
`scripts/test-workflow-scripts.mjs` (`branching: a stranded publication, localized seam by
seam`) that builds the measured shape offline: a base carrying a feedback record and a
generated `.workaholic/feedbacks/index.md`, and two `work-*` publication branches — no claim
commit on either, which is exactly what `publish-tree-pr.sh` pushes — with the base then
advanced so one collides on the generated index alone and one also on a source file.

**Seam 1, the classification: sound.** `conflict_class_mechanical` answers `mechanical` for a
flat area's index when all three sides carry the `okf:generated` markers, and `content` when
any side lacks them — the marker-absent case a repository on an older generator would be in.
Probed as the predicate it is, with three blobs, so both cases are reachable without a second
repository.

**Seam 2, the reading: sound.** `claim-mergeability.sh` takes a **branch**, not a claim, so it
answers for a publication with no change at all: `mechanical` for the index-only collision,
naming `.workaholic/feedbacks/index.md` as the file it collided on, and `content` for the
source-file one.

**Seam 3, the act's candidate set: this is what stops the repair.** A publication carries no
`Claim …` commit, and the claim scan keys on that commit subject rather than on the branch
name — its own header says so, deliberately. So `list-claims.sh` gives it no row, and
`list-catchable-claims.sh`, whose candidates are `report_undelivered` or `queue_drained`
**claims**, answers `count: 0` over a settleable collision. Nothing excludes it by a verdict,
an identity or a heartbeat: it was never a candidate to exclude.

The finding is pinned as a **closed set** rather than as "nothing catches it up" — every
consumer of the mergeability reading is enumerated, so the row keeps meaning something once
the repair exists and fails the moment some other path grows one of its own. It is written
into the mission's `## Changelog`, so the remaining tickets are built on the measurement
rather than on the proposal's guess.

### Discovered Insights

- **Insight**: the proposal's hypothesis was wrong in a useful direction — it guessed the
  classifier, and the classifier had already been fixed for this exact shape on 2026-08-29.
  **Context**: `conflict_class_generated_region` was written for `.workaholic/*/index.md` by
  proof, and a reader who stops at "the index conflicts" will keep re-deriving a repair that
  already exists one seam in. The missing piece is never the rule; it is who is allowed to
  ask it.
- **Insight**: `publish-tree-pr.sh` deliberately mints a `work-YYYYMMDD-HHMMSS` name for a
  publication and relies on the absence of a claim commit to stay invisible to the oracle.
  **Context**: that invisibility is load-bearing (a publication must never be claimed or
  driven) and is exactly why a publication needs its **own** reader rather than a loosened
  claim one. Any repair that widens the claim vocabulary to cover publications is undoing a
  property the protocol depends on.
