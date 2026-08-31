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

Development completed as planned. The state has a name, a classification, a question, and two
siblings that count it instead of asking their own wrong question about it.

**A verdict word, not a field beside the existing verdict** (step 1's decision, and the reason).
The two states call for different next actions — retire the claim versus tell a person their
work is stranded — and a field beside `superseded` would have left every existing consumer
reading the word alone and acting on it, which is exactly the failure the mission opened with.
`stranded` follows `awaiting_verification`'s precedent: emitted by `lib/claims.sh` and nowhere
else, classified in one table, `resumable: false`, and sitting where `superseded` sat in the
chain — after `claim_active`, before the drained fork.

The proof was split into `claims_delivered` (are this unit's tickets on the base) and the diff
reading, composed by `claims_delivery` into three words — `superseded`, `stranded`, `none`.
`claims_superseded` keeps its name and its meaning for every consumer outside the library. An
**`unanswerable`** diff is `none`, never `stranded`: it is the absence of a reading, and the two
failures it must not cause are opposite — calling it `superseded` licenses a delete, calling it
`stranded` sends a person after a branch nobody could read.

**Classified as a judgement** in `drive/reference/claims.md`'s verdict table: nothing may merge,
close, delete, revert, retire, claim or hold work on it. `plan-units.sh` excludes it
`claimed_stranded` and offers it to nothing — not `resumable[]`, not `undelivered[]`, and **not**
`resurveyed[]`, which takes only `superseded` (there is no queued work to hand back either way,
because the unit's tickets are already archived on the base). `claim.sh` refuses it under its own
word rather than a generic denial.

**The question** is `/moderate`'s new `stranded-branches` step (§32 of the workflow reference),
keyed `stranded-branch:<unit>` so one branch costs one question however many ticks see it, and
addressed to the **claim holder** — the person who wrote what is on the branch. It names the
files through `drive/scripts/stranded-claim-detail.sh`, the reading the verdict was derived from
carried verbatim, bounded then counted, read once per candidate and for nothing else; a candidate
whose files could not be read is reported unresolved rather than asked about with a blank list.
The condition's age rides the heading through `lib/read-age.sh`, the reader's words verbatim.
Composed to the catalog's contract: the plain fact first, the identifier after it, and the body
naming the one act — the ruling.

**The siblings filter and count.** `stalled-units` drops `stranded` from its candidate set in
the same expression that already drops `superseded` and `awaiting_verification`, and counts it in
its summary; `retire-claims` cannot reach the row at all now and counts it too, so the fact is
never silently lost. One step asks and the others count.

**What happens to a branch nobody answers about** is stated in the step spec rather than left to
be discovered: it stays stranded. The question is asked once, its age rides the heading, and the
tick touches the branch — never. No automatic recovery path was added, because which of porting,
opening as its own pull request, or discarding deliberately is right is precisely what the step
exists to ask.

### Discovered Insights

- **Insight**: a verdict word cannot be assigned from a variable if the suite parses the
  emissions out of the source.
  **Context**: `testProofJudgementSplit` builds the emitted set from `^\s*_cs_reason=([a-z_]+)$`,
  so `_cs_reason="$_cs_delivery"` would have made both `superseded` and `stranded` read as words
  the table classifies and the library never emits. The chain keeps two literal assignments
  inside an `if`, and the three-valued reading is computed once by riding the `elif`'s own
  condition list (`elif var=$(…); [ test ]; then`) — which is also what keeps the mission grain
  from spending a second network call per delivered claim.
- **Insight**: the step count is pinned in five places, and four of them are derived.
  **Context**: `run.sh`'s `STEPS` line is the source; the suite's own `STEPS` array, the
  log-line count, the re-entered-tick count and the deadline test all key off it, and
  `testFindingClassification` requires every step id to be classified in `workflow.md`. Adding a
  step is one line in `run.sh` and one row in the classification table — and then five
  assertions tell you, by name, everything else that has to move.
