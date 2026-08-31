---
created_at: 2026-08-31T20:22:50+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: repair-a-mechanically-resolvable-conflict-instead-of-reporting-it
merge_policy:
verification_handoff: 
---

# Ask about a publication only a person can settle

## Overview

PROPOSED. Once the act settles what a generator can settle, what is left is a conflict that
genuinely needs a person — and the measured failure is that nobody was told, for days, while
the hourly tick reported the blockage to nobody in particular. `/moderate`'s `catchup-blocked`
step asks about a `content` conflict on a **reported claim** only, so a stranded publication
reaches no question at all. This ticket gives it one, and the step asks and does nothing else.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-catchup-blocked.sh` — the sibling step to
  model on, and where the boundary between the two candidate sets must be stated.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's own spec, including
  what its question must carry.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` and `lib/question-id.sh` — the
  one asking seam and the one derivation of a question id.
- `plugins/workaholic/skills/moderate/scripts/lib/read-age.sh` — how long the condition has
  been standing, keyed on the key the step composes.

## Implementation Steps

1. Add the step over the reader, with its own question key per publication (one subject, one
   question, however many ticks see it).
2. **One step asks and the other filters.** Whichever set the new step takes, subtract it
   from `catchup-blocked`'s candidates and count it there instead — the `retire-claims` /
   `stalled-units` pairing is the precedent, and either half alone is a defect.
3. Compose the question to the catalog's contract: lead with what happened in words a reader
   outside the repository understands, the identifier after it, never a verdict word alone,
   and the body names the one act asked of the addressee. The files the conflict collided on
   ride the heading.
4. Address it to the publication's author. A publication the loop opened for the operator
   deliberately (`strategy_touching`, `ruling_touching`) is `operator-pulls`' subject and
   must not be asked about twice.
5. Attach the condition's age through `lib/read-age.sh`, the reader's words verbatim, an
   unreadable age named as unreadable and an absent one not mentioned. No step summary may
   carry an age or a timestamp.
6. Degrade by name: an unreadable read is `degraded` with its reason, never a step that ran
   and found nothing.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A publication with a `content` conflict produces exactly one question, addressed to its
  author, naming the files it collided on.
- The same publication asked about on an earlier tick is not asked about again.
- `catchup-blocked` counts what the new step took rather than asking about it too.
- The step merges nothing, closes nothing, pushes nothing and touches no claim.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic rows in `scripts/test-workflow-scripts.mjs` over a seeded tick log.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- No `AskUserQuestion` anywhere in the step.
- The question body is self-contained inside the catalog's ceiling; a question that will not
  fit is aimed at the wrong reader and is rewritten, not stretched.

## Considerations

- The hourly report that told nobody is the failure this repairs, so resist adding a status
  line addressed to nobody: two such roots have already been retired for exactly that.
- Whether the new key belongs in the `file-findings` classification table is a decision this
  ticket must make explicitly — an unclassified step id reads `needs_ruling`, which may well
  be the right answer for a conflict whose cause the reading cannot state.

## Final Report

Development completed as planned.
`plugins/workaholic/skills/moderate/scripts/step-stranded-publications.sh` is the step, keyed
`stranded-publication:<number>`, registered in `run.sh`'s `STEPS` beside its claim-side
siblings and specified in `moderate/reference/workflow.md` §32. It **asks and nothing else**:
no merge, no catch-up, no push, no close, no claim touched, no gate lifted, no
`AskUserQuestion`, and nothing written anywhere but its own tick-log line, which `run.sh`
writes.

**Only `content` draws a question.** `mechanical` is the loop's own work — `/implement` settles
it through `settle-stranded-publication.sh`, and asking about it would ask a person for the act
the machinery is about to take. `clean` needs no catch-up. `unanswerable` is the **absence** of
a reading, never actable and never a question addressed to somebody who can do nothing with it;
it is **counted** in the summary so it stays visible. The question is composed to the catalog's
contract — what happened first, in words a reader outside the repository understands, then the
pull request, then the files both sides changed, then the one act asked of the addressee — and
the age rides `lib/read-age.sh`, the reader's words verbatim. The summary carries no age and no
timestamp.

**Two decisions this ticket had to make explicitly, both made and recorded:**

1. **The `file-findings` classification is `needs_ruling`**, not the unclassified default —
   `catchup-blocked`'s row for `catchup-blocked`'s reason: which side of a content collision
   keeps its meaning is the author's, and the loop refused it precisely because it must not
   decide. The half that *is* repairable is not a finding at all, because `/implement` is
   already settling it.
2. **No filter was added to `catchup-blocked`, and the reason is recorded rather than a
   counter that could only ever be zero.** The ticket asked for the `retire-claims` /
   `stalled-units` division; it does not apply, because the two candidate sets are disjoint
   **by construction and from both sides**: `catchup-blocked` draws from `list-claims.sh`,
   whose rows are branches carrying a `Claim …` commit, which a publication never has; and
   this step's own reader drops any branch the oracle names. `merge-conflicts` may still
   report the same pull request, and that is deliberate on its own recorded reasoning — it
   **asks nobody anything**, so the only question a person receives about such a publication
   is this one. The precedent for declining to add a filter is written in
   `step-catchup-blocked.sh`'s own header, whose 2026-08-30 widening had the same honest
   outcome: a recorded finding and no change. The disjointness is **pinned by the suite**
   rather than left to a reading of two headers.

**Verified**: `node scripts/test-workflow-scripts.mjs` — the hermetic row
(`moderate/stranded-publications: the collision only a person can settle`) proves one keyed
candidate naming the pull request and the colliding files, an event supplied, a degraded read
named by the reader's own word with nobody asked, an age- and timestamp-free summary, a
byte-identical checkout, and the disjointness from both sides.

### Discovered Insights

- **Insight**: "one step asks and the other filters" is a rule about **overlapping candidate
  sets**, not a shape to copy.
  **Context**: where the sets cannot overlap, adding the filter costs a permanently-zero
  counter in a summary that is diffed hourly against the previous tick — noise in exactly the
  place this repository has twice retired status roots to keep quiet.
- **Insight**: the three sibling steps that could each see a publication answer differently by
  design — `merge-conflicts` reports and asks nobody, `operator-pulls` owns the deliberate
  ones, and this owns the stranded ones.
  **Context**: the boundary lives in the **reader's** membership terms, so all three stay
  consistent by composing one derivation instead of three headers agreeing with each other.
