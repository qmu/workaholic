---
created_at: 2026-08-31T20:34:54+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-a-claim-branch-is-empty-before-deleting-it
merge_policy:
verification_handoff: 
---

# Tell a person about a stranded claim branch

## Overview

PROPOSED. The ask names the state directly: a branch whose tickets are archived but whose diff
is non-empty is *a real and different state — the work is stranded, not finished, and it wants
a person told rather than a branch deleted*. Once the previous ticket stops calling it
finished, that state exists and belongs to nobody. This ticket names it and routes it to its
holder, and does nothing else — no merge, no close, no delete, no claim touched.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — where a verdict word is emitted,
  and the only place one may be.
- `plugins/workaholic/skills/drive/reference/claims.md` — the verdict table and the *Proofs and
  judgements* classification; the new word is a **judgement**, never a proof.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step spec and what its
  question must carry.
- `plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh` — the filter/ask pairing
  precedent: one step asks and its sibling filters, and either half alone is a defect.

## Implementation Steps

1. Name the state. Decide between a verdict word of its own and a field beside the existing
   verdict, and record the reason — the protocol's rule is that a word is emitted only by
   `lib/claims.sh` and classified in one table, so whichever is chosen goes in one place.
2. Classify it as a **judgement**, not a proof, in `drive/reference/claims.md`: nothing may
   merge, close, delete, gate or hold work on it. It is reported and asked about.
3. Add the `/moderate` question, keyed per unit so one branch costs one question however many
   ticks see it, addressed to the claim holder.
4. Compose the question to the catalog's contract: lead with what happened in words a reader
   outside the repository understands, the identifier after it, never a verdict word alone,
   and the body names the one act asked of the addressee. The files stranded on the branch ride
   the **heading**, bounded to a few names and then a count.
5. Filter it out of the sibling steps that would otherwise ask about the same branch —
   `stalled-units` and `retire-claims` — and **count** it there instead, following the existing
   pairing rather than inventing a second convention.
6. Attach the condition's age through `lib/read-age.sh`, the reader's words verbatim, keyed on
   the key the step composes. No step summary may carry an age or a timestamp.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A stranded branch produces exactly one question, addressed to its holder, naming the files.
- The same branch is not asked about again on a later tick.
- `stalled-units` and `retire-claims` count it rather than asking about it too.
- The step merges nothing, closes nothing, deletes nothing and touches no claim.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic rows in `scripts/test-workflow-scripts.mjs` over the reproduction plus a seeded tick
  log, including the sibling-step filter.
- `node scripts/test-workflow-scripts.mjs`, which fails on a verdict word no table classifies.

**Gate** — what must pass before approval:

- No `AskUserQuestion` anywhere in the step.
- The new word appears in exactly one emitter and exactly one classification table.

## Considerations

- The right act for a stranded branch is genuinely unclear and is **not** this ticket's to
  decide: the work may want porting onto a live branch, opening as its own pull request, or
  discarding deliberately. The question asks the holder; nothing here chooses for them, and no
  automatic recovery path is added.
- A branch stranded for weeks with nobody answering is a real possibility. Say in the step spec
  what happens then — the age rides the question and the question is asked once — rather than
  letting a silent backlog accumulate unremarked.

## Final Report

Development completed as planned. Steps 1–3 had landed with the verdict (2026-09-01, issue #788):
the state is named by a **verdict word** rather than a field, emitted only by `lib/claims.sh`,
classified as a **judgement** in one table, and asked about by `/moderate`'s `retire-claims` step
keyed `stranded-unit:<unit>`. What was missing was everything that makes the question answerable
— steps 4, 5 and 6.

- **The files ride the question** (step 4). `list-claims.sh` renders `stranded_files` (bounded)
  and `stranded_file_count` (the true total) on a `stranded` row and on **no other** — the
  listing costs a second `git diff`, and every other row's emptiness is already `true` or is not
  about emptiness at all. `step-retire-claims.sh` reads them off the row rather than calling the
  emptiness reader again, on `mergeability_content_files`' own precedent: the one consumer that
  must name something reads it from the row, because two reads of one fact drift. The `compose`
  instruction was rewritten to the catalog's contract — lead with what happened in ordinary
  words, the identifier **after** it, name the files, and never suggest deleting the branch.
- **The sibling filter** (step 5). `stalled-units` now filters `stranded` in the **same
  expression** as `superseded` and `awaiting_verification` — one rule with three verdicts, not
  three mechanisms — and **counts** it in the summary. A stranded unit is not stalled: it has
  been *orphaned*, and *a claimed unit has not moved for a day or more* sends a person looking
  for a run that died. **One step asks and the other filters, and either half alone is a
  defect**; without this the same branch drew two differently-worded questions.
- **The age** (step 6), through `lib/read-age.sh`, keyed on the key the step already composed,
  the reader's words verbatim. The question is asked **once**, so the age is the only thing that
  can say how long a branch has been standing unanswered — which is what the ticket's own
  Considerations asked be said rather than left to a silent backlog. The step summary carries no
  age and no timestamp, so the moderation root's change diff is untouched.
- **Hermetic rows** over a real claim fixture prove the row carries the files, the question is
  keyed once and names branch, files and age, the step writes nothing and offers no retirement,
  and `stalled-units` asks nothing while counting it.

### Discovered Insights

- **Insight**: The two payloads (`blocked_retirements` and `stranded_claims`) must stay separate
  inside one `needs_agent`, and the reason is not tidiness: a blocked retirement asks *please
  delete this branch* and a stranded claim asks *do not delete this, it holds work nothing else
  has*. One payload carrying both would be a single instruction with two contradictory actions.
  **Context**: A later refactor merging them "because they are both about branches" would produce
  questions that tell a person to delete work.
- **Insight**: `moderate/reference/workflow.md` had no `stranded` spec at all — the verdict, the
  question key and the payload all existed in the script while the document that governs what a
  question must carry said nothing. That is how a question ends up composed from whatever
  identifier the step happened to hold.
  **Context**: A step's question is specified in the workflow reference, not in the script; a key
  that exists in only one of the two is a question nobody has ruled on the content of.
