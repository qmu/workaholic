---
created_at: 2026-09-02T04:26:30+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: resolve-a-conflicted-pull-request-in-the-tick-not-report-it
merge_policy:
verification_handoff: 
---

# Let the tick resolve a content conflict, not defer it

## Overview

PROPOSED. The tick's current line — "we do not rebase here; generated-index conflicts are
catch-up's to resolve and content conflicts belong to the claim holder" — is the operator's
central correction: completely wrong. The tick must bring every conflicted pull request into
a mergeable state itself, rebasing or merging as appropriate.

Today `content` is a terminal refusal everywhere it appears: `catch-up-claim.sh` refuses
`content_conflict`, `settle-stranded-publication.sh` refuses `not_mechanical:<class>`, and
`/moderate`'s `catchup-blocked` and `stranded-publications` steps turn that refusal into a
question addressed to a claim holder. This ticket gives the tick a resolution act for the
class it currently declines.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — what an unattended act may do, and what it must prove first

## Key Files

- `plugins/workaholic/skills/ship/scripts/catchup-main.sh` — the one merge engine; the
  resolution composes it and never becomes a second one.
- `plugins/workaholic/skills/ship/scripts/lib/conflict-class.sh` — the one classification
  rule; `content` keeps its meaning, what changes is what the caller does with it.
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` — refuses `content_conflict`
  today; the act is added beside that refusal.
- `plugins/workaholic/skills/branching/scripts/settle-stranded-publication.sh` — the same
  refusal on the publication side.
- `plugins/workaholic/skills/drive/reference/claims.md` — where an act's licence, its
  idempotence and its refusal vocabulary are contracted.
- `plugins/workaholic/skills/moderate/SKILL.md`, `CLAUDE.md` — the bounds prose this widens.

## Implementation Steps

1. Reproduce a `content` conflict offline in a throwaway repository — two branches editing
   the same lines of one file — and confirm today's refusal, so the change is measured
   against a real case rather than a described one.
2. Decide and state the resolution strategy per class, in `claims.md`, before writing it:
   which side wins for a generated file, what a regenerable file does, and what happens to a
   genuinely divergent hand-written hunk. The operator's instruction is that the tick
   decides; that decision must be written down where a reader can argue with it.
3. Implement the act by composing `catchup-main.sh` — never a second merge engine — and
   regenerate with the repository's own tooling afterwards, exactly as the mechanical path
   already does.
4. Run the repository's fast checks before pushing, and refuse `validation_failed:<check>`
   rather than pushing a resolution that does not build. This is the one bound that is not
   negotiable: resolving must not mean shipping something broken.
5. Keep every act property `claims.md` already requires: re-derive the class at the moment
   of the act, be idempotent, be reversible, and refuse every bound by its own word with
   nothing pushed.
6. Widen the bounds prose in `workaholic:moderate` and `CLAUDE.md` in the same change — the
   tick used to say it never pushes into a branch the claim protocol owns, and that sentence
   is now false. Say what it may do and what it still may not.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `content`-classed pull request the tick can settle is brought to mergeable by the tick.
- The resolution strategy is written down per class before it is applied.
- A resolution that fails the repository's fast checks is refused, with nothing pushed.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- The offline reproduction from step 1, re-run: refusal before, resolution after.

**Gate** — what must pass before approval:

- The act is idempotent: running it twice leaves the branch byte-identical after the first.
- A refusal path leaves no worktree and no pushed ref behind.

## Considerations

- This widens what an unattended tick may write, and the widening is the operator's
  instruction rather than the loop's own reading. Bound it in the code and say so in the
  prose: fast checks before every push, one merge engine, refusals by name.
- A resolution that silently discards a person's hunk is the failure mode to design
  against. Where a hunk cannot be resolved without losing behaviour, the honest act is to
  refuse by name — and that residue is what the mission's third acceptance item is about.

## Final Report

Development completed as planned.

**Step 1, the offline reproduction, came first and it changed the design.** Two branches
editing the same middle line of one file, in a throwaway repository: `git merge-tree
--write-tree` exits 1, `conflict_class.sh` answers `content` (the path is outside the
append-only scope and matches no mechanical rule), and both acts refused before checking
anything out. That confirmed today's refusal — and it also showed what the honest widening
is *not*. The `content` class is, by construction, everything the mechanical and append-only
**proofs** could not accept, so "resolve a content conflict" cannot mean giving a machine a
new judgement: there is nothing left in that class that can be settled without one.

**What the reproduction did expose is that `content` is a PREDICTION, not a finding.**
`claim-mergeability.sh` is a reader. It runs `git merge-tree` from an empty directory with
`GIT_DIR` set, deliberately, so the repository's own `.gitattributes` is out of reach —
because its job is to predict **GitHub**, which applies no merge driver when it computes
`mergeable`. The writer, `catchup-main.sh`, merges in a **real checkout**, where the
`merge=union` attribute this repository committed for its generated OKF indexes is in force.
The tree already records the measurement (`claim-mergeability.sh`'s header, 2026-09-01,
ticket `20260901041500`): same git, same two commits, the checkout merge exits 0 while the
attribute-less computation exits 1. **The reader is pessimistic by construction against the
writer**, and both acts were refusing on its guess — so every branch in that gap was declined
by a machine and handed to a claim holder who, in the operator's words, never comes.

**So the refusal moved rather than went.** `catch-up-claim.sh` and
`settle-stranded-publication.sh` now accept a `content` prediction as a **candidate**,
attach the worktree, and perform the merge; the refusal is raised from the **writer's own
residue** — still `content_conflict`, still with nothing pushed and the branch
byte-identical, and still reaching a person through `/moderate`. The tick now finds out by
trying.

### What this deliberately did NOT do

- **`conflict-class.sh` is untouched.** No path was reclassified, no proof was loosened, and
  no judgement moved to a machine. The one classification rule still has one home.
- **No second merge engine.** Both acts compose `catchup-main.sh`, as they already did.
- **`unanswerable` keeps its refusal on both paths.** It is the *absence* of a reading, and
  acting on an absence is exactly what a three-valued word exists to prevent
  (`claims.md`, *Proofs and judgements*). It is also still never offered as a candidate —
  offering one the act must refuse spends a worktree to learn nothing.
- **Every other bound is where it was**: the repository's fast checks still gate every push
  and still refuse `validation_failed:<check>` with nothing pushed; a colleague's claim is
  still untouchable; `claim_active` still leaves a live branch alone; a scan-held pull
  request is still refused `scan_held:<tier>`; and the act still re-derives its own verdict
  at the moment of the act rather than trusting a handed-in list.

### The change

- `drive/scripts/catch-up-claim.sh` — the class gate accepts `content`; the header's refusal
  list and its narrowing paragraph say the refusal is the writer's residue.
- `branching/scripts/settle-stranded-publication.sh` — the same, with `NEEDS_CATCHUP=true`
  for `content` (it needs the merge that `clean` does not).
- `drive/scripts/list-catchable-claims.sh` — offers `content` beside `mechanical`, and now
  **carries the class through** instead of re-spelling the literal `mechanical` into every
  candidate. That re-spelling was harmless while one word was admitted and became a lie the
  moment a second was.
- `drive/reference/claims.md` — step 2's requirement: *The resolution strategy, per class*,
  a table saying which side wins for a generated file, what a regenerable region does, what
  the union driver settles and why its cost is repaired rather than shipped, and what happens
  to a divergent hand-written hunk. The `content` row and the bounded-act consumer row moved
  with it.
- `moderate/SKILL.md`, `CLAUDE.md`, `drive/SKILL.md` — the bounds prose, including the
  who-repairs-each-class table, which gained an explicit `unanswerable` row.
- `scripts/test-workflow-scripts.mjs`, `scripts/e2e/loop-drill.sh`,
  `docs/loop-drill-runbook.md` — the assertions below.

### Verification

- `node scripts/test-workflow-scripts.mjs` — **6028 passed, 0 failed.**
- `sh scripts/e2e/loop-drill.sh verify-catch-up` — `pass`, 15 load-bearing rows, 3 breakers.
- `sh scripts/e2e/loop-drill.sh verify-all` — the classified set.
- `node scripts/build-plugins/{build,verify,validate-metadata}.mjs` — regenerated and clean.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` — `conforming: true`.

**Two existing rows caught the behaviour change, which is the evidence the change is real.**
The publication test expected `not_mechanical:content` (refused *before* attempting) and got
`content_conflict` (refused *after*); the `verify-catch-up` drill asserted `batch-content`
was not a candidate. Both were updated to the new bound rather than worked around, and the
drill row was **split in two** — one row for the widening, one for the identity bound that
did not move — because collapsing them is how a colleague's claim would quietly become
offerable the next time somebody widens the other half.

**Six new assertions pin the shape**, each written to fail on the change that would undo it:
the class gate accepts `content` in both acts; `unanswerable` is still refused in both; the
candidate reader offers `content` and carries the class verbatim; and `claims.md` still
states the strategy.

### Discovered Insights

- **Insight**: The safety property of the widened path is proved by a row that already
  existed and did not change — *and its branch is byte-identical after the refusal*. A
  `content` publication now really is checked out and really is merged before it is refused,
  and the ref still does not move, because nothing is pushed until the fast checks pass.
  **Context**: That is the whole argument for why attempting is free. Anyone tempted to add
  a pre-flight refusal back "to save the worktree" should read that row first: the cost of
  attempting is a temp checkout, and the cost of not attempting was every branch the writer
  could have finished.

- **Insight**: `catchup-main.sh` runs `git merge --abort` on **both** of its failure paths
  (an unresolved mechanical remainder and a content conflict), so a refused attempt leaves
  the worktree clean rather than sitting on a conflicted index.
  **Context**: This is what makes the widening idempotent. Without it, the first `content`
  attempt would leave a conflicted worktree and every later run would refuse
  `dirty_worktree` — turning a widening into a self-inflicted permanent block. It was
  checked before the gate was opened, not assumed.

- **Insight**: A reader and a writer of the same conflict answer differently **on purpose**
  here, and neither is wrong: the reader is calibrated to GitHub's attribute-free merge and
  the writer to the repository's own. The shared `conflict-class.sh` keeps their
  *classification* identical while their *inputs* differ.
  **Context**: The existing comment in `conflict-class.sh` warns that two copies of the rule
  would let them disagree. The subtler hazard is the opposite one: because their inputs
  differ, agreement is not guaranteed even with one rule — so a caller must decide which of
  the two it is trusting for a given decision. For *predicting a remote merge*, the reader;
  for *deciding whether a person is needed*, the writer.
